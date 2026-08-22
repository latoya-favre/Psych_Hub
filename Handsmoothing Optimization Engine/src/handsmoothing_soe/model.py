from __future__ import annotations

from dataclasses import asdict, dataclass
import math
import time
from typing import Sequence

from ortools.sat.python import cp_model


@dataclass(frozen=True)
class SolverConfig:
    score_min: int = 1
    score_max: int = 19
    fixed_first: int | None = 1
    fixed_last: int | None = 19
    max_step: int = 2
    target_mean: float = 10.0
    mean_tolerance: float = 0.30
    sd_min: float = 2.70
    sd_max: float = 3.30
    frequency_scale: int = 10_000
    fidelity_weight: int = 100
    changed_cell_weight: int = 20
    roughness_weight: int = 1
    time_limit_seconds: float = 10.0
    workers: int = 8


@dataclass(frozen=True)
class CurveProblem:
    name: str
    raw_scores: Sequence[int]
    empirical_scores: Sequence[int]
    frequencies: Sequence[float]

    def validate(self) -> None:
        lengths = {len(self.raw_scores), len(self.empirical_scores), len(self.frequencies)}
        if len(lengths) != 1 or not self.raw_scores:
            raise ValueError(f"{self.name}: raw scores, empirical scores, and frequencies must have equal nonzero length")
        if any(b <= a for a, b in zip(self.raw_scores, self.raw_scores[1:])):
            raise ValueError(f"{self.name}: raw scores must be strictly increasing")
        if any(f < 0 or not math.isfinite(f) for f in self.frequencies):
            raise ValueError(f"{self.name}: frequencies must be finite and nonnegative")
        if sum(self.frequencies) <= 1:
            raise ValueError(f"{self.name}: total frequency must exceed 1")


@dataclass(frozen=True)
class CurveSolution:
    name: str
    status: str
    solve_seconds: float
    objective_value: float | None
    scores: list[int] | None
    weighted_mean: float | None
    weighted_sd: float | None
    changed_cells: int | None
    absolute_adjustment: int | None
    weighted_absolute_adjustment: float | None
    roughness: int | None

    def to_dict(self) -> dict:
        return asdict(self)


def _weighted_stats(scores: Sequence[int], frequencies: Sequence[float]) -> tuple[float, float]:
    n = sum(frequencies)
    total = sum(f * x for f, x in zip(frequencies, scores))
    total_sq = sum(f * x * x for f, x in zip(frequencies, scores))
    mean = total / n
    variance = (total_sq - total * total / n) / (n - 1)
    return mean, math.sqrt(max(0.0, variance))


def solve_curve(problem: CurveProblem, config: SolverConfig = SolverConfig()) -> CurveSolution:
    problem.validate()
    if config.frequency_scale <= 0:
        raise ValueError("frequency_scale must be positive")
    if config.score_min > config.score_max:
        raise ValueError("score_min cannot exceed score_max")
    if config.sd_min < 0 or config.sd_min > config.sd_max:
        raise ValueError("SD bounds are invalid")

    model = cp_model.CpModel()
    row_count = len(problem.raw_scores)
    weights = [max(0, round(f * config.frequency_scale)) for f in problem.frequencies]
    n = sum(weights)
    if n <= config.frequency_scale:
        raise ValueError(f"{problem.name}: scaled total frequency must exceed frequency_scale")

    scores = [model.new_int_var(config.score_min, config.score_max, f"score_{r}") for r in range(row_count)]
    squared_scores = [
        model.new_int_var(config.score_min**2, config.score_max**2, f"score_squared_{r}")
        for r in range(row_count)
    ]
    square_table = [(x, x * x) for x in range(config.score_min, config.score_max + 1)]
    for score, squared in zip(scores, squared_scores):
        model.add_allowed_assignments([score, squared], square_table)

    if config.fixed_first is not None:
        model.add(scores[0] == config.fixed_first)
    if config.fixed_last is not None:
        model.add(scores[-1] == config.fixed_last)
    for left, right in zip(scores, scores[1:]):
        model.add(right >= left)
        model.add(right - left <= config.max_step)

    weighted_sum = model.new_int_var(n * config.score_min, n * config.score_max, "weighted_sum")
    weighted_sum_sq = model.new_int_var(n * config.score_min**2, n * config.score_max**2, "weighted_sum_sq")
    model.add(weighted_sum == sum(w * x for w, x in zip(weights, scores)))
    model.add(weighted_sum_sq == sum(w * x2 for w, x2 in zip(weights, squared_scores)))

    target_sum = round(config.target_mean * n)
    mean_tolerance = round(config.mean_tolerance * n)
    model.add(weighted_sum >= target_sum - mean_tolerance)
    model.add(weighted_sum <= target_sum + mean_tolerance)

    weighted_sum_squared = model.new_int_var((n * config.score_min) ** 2, (n * config.score_max) ** 2, "weighted_sum_squared")
    model.add_multiplication_equality(weighted_sum_squared, [weighted_sum, weighted_sum])
    variance_numerator = model.new_int_var(0, config.score_max**2 * n * n, "variance_numerator")
    model.add(variance_numerator == n * weighted_sum_sq - weighted_sum_squared)
    variance_denominator = n * (n - config.frequency_scale)
    # SD limits are configured to two decimal places. A scale of 100 retains
    # that precision while keeping the largest linearized variance
    # coefficients inside CP-SAT's signed 64-bit integer domain for norm
    # samples such as VC (N=180 with frequency_scale=10_000).
    variance_scale = 100
    model.add(variance_scale * variance_numerator >= round(config.sd_min**2 * variance_scale) * variance_denominator)
    model.add(variance_scale * variance_numerator <= round(config.sd_max**2 * variance_scale) * variance_denominator)

    deviations = []
    changed_flags = []
    for row, (score, empirical) in enumerate(zip(scores, problem.empirical_scores)):
        deviation = model.new_int_var(0, config.score_max - config.score_min, f"deviation_{row}")
        model.add_abs_equality(deviation, score - int(empirical))
        changed = model.new_bool_var(f"changed_{row}")
        model.add(deviation == 0).only_enforce_if(changed.Not())
        model.add(deviation >= 1).only_enforce_if(changed)
        deviations.append(deviation)
        changed_flags.append(changed)

    roughness_terms = []
    for row in range(1, row_count - 1):
        roughness = model.new_int_var(0, 2 * config.max_step, f"roughness_{row}")
        model.add_abs_equality(roughness, scores[row + 1] - 2 * scores[row] + scores[row - 1])
        roughness_terms.append(roughness)

    model.minimize(
        config.fidelity_weight * sum(w * d for w, d in zip(weights, deviations))
        + config.changed_cell_weight * sum(changed_flags)
        + config.roughness_weight * sum(roughness_terms)
    )

    solver = cp_model.CpSolver()
    solver.parameters.max_time_in_seconds = config.time_limit_seconds
    solver.parameters.num_search_workers = config.workers
    started = time.perf_counter()
    status = solver.solve(model)
    elapsed = time.perf_counter() - started
    status_name = solver.status_name(status)
    if status not in (cp_model.OPTIMAL, cp_model.FEASIBLE):
        return CurveSolution(problem.name, status_name, elapsed, None, None, None, None, None, None, None, None)

    solution = [solver.value(x) for x in scores]
    mean, sd = _weighted_stats(solution, problem.frequencies)
    changed = sum(x != int(y) for x, y in zip(solution, problem.empirical_scores))
    absolute_adjustment = sum(abs(x - int(y)) for x, y in zip(solution, problem.empirical_scores))
    weighted_adjustment = sum(f * abs(x - int(y)) for f, x, y in zip(problem.frequencies, solution, problem.empirical_scores))
    roughness = sum(abs(solution[r + 1] - 2 * solution[r] + solution[r - 1]) for r in range(1, row_count - 1))
    return CurveSolution(
        problem.name,
        status_name,
        elapsed,
        solver.objective_value,
        solution,
        mean,
        sd,
        changed,
        absolute_adjustment,
        weighted_adjustment,
        roughness,
    )
