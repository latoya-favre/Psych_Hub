from __future__ import annotations

"""Handsmoothing Optimization Engine — Part B: CP-SAT optimization.

Operational, self-contained script. It depends only on Part A's JSON artifact,
the source workbook named in that artifact, and installed third-party packages.
"""

import argparse
import csv
from dataclasses import asdict, dataclass
import hashlib
import json
import math
import os
from pathlib import Path, PurePosixPath
import re
import time
from typing import Sequence
from xml.etree import ElementTree
from zipfile import ZIP_DEFLATED, ZipFile, ZipInfo

from ortools.sat.python import cp_model


# =====================================================
# Handsmoothing Optimization Part B — CONFIGURATION
# =====================================================

PROJECT_DIR = Path(r"C:\Users\UFAVRLA\PythonProjects\Handsmoothing Optimization Engine")
PART_A_DIR = PROJECT_DIR / "outputs" / "wais_mr_reconstructed"
PART_A_FILE = PART_A_DIR / "part_a_dataprep.json"
OUTPUT_DIR = PROJECT_DIR / "outputs" / "wais_mr_reconstructed" / "part_b"
OUTPUT_WORKBOOK_NAME = "optimized_mr_handsmoothing.xlsx"

SCORE_MIN = 1
SCORE_MAX = 19
FIXED_FIRST = 1
FIXED_LAST = 19
MAX_STEP = 2
TARGET_MEAN = 10.0
MEAN_TOLERANCE = 0.30
SD_MIN = 2.70
SD_MAX = 3.30
FREQUENCY_SCALE = 1
FIDELITY_WEIGHT = 100
CHANGED_CELL_WEIGHT = 20
ROUGHNESS_WEIGHT = 1
TIME_LIMIT_SECONDS = 10.0
NUM_WORKERS = 8

PART_A_OVERRIDE = os.environ.get("HANDSMOOTHING_PART_A_FILE", "").strip()
OUTPUT_OVERRIDE = os.environ.get("HANDSMOOTHING_PART_B_OUTPUT_DIR", "").strip()


@dataclass(frozen=True)
class SolverConfig:
    score_min: int = SCORE_MIN
    score_max: int = SCORE_MAX
    fixed_first: int | None = FIXED_FIRST
    fixed_last: int | None = FIXED_LAST
    max_step: int = MAX_STEP
    target_mean: float = TARGET_MEAN
    mean_tolerance: float = MEAN_TOLERANCE
    sd_min: float = SD_MIN
    sd_max: float = SD_MAX
    frequency_scale: int = FREQUENCY_SCALE
    fidelity_weight: int = FIDELITY_WEIGHT
    changed_cell_weight: int = CHANGED_CELL_WEIGHT
    roughness_weight: int = ROUGHNESS_WEIGHT
    time_limit_seconds: float = TIME_LIMIT_SECONDS
    workers: int = NUM_WORKERS


@dataclass(frozen=True)
class CurveProblem:
    name: str
    raw_scores: Sequence[int]
    empirical_scores: Sequence[int]
    frequencies: Sequence[float]

    def validate(self) -> None:
        if len({len(self.raw_scores), len(self.empirical_scores), len(self.frequencies)}) != 1 or not self.raw_scores:
            raise ValueError(f"{self.name}: input vectors must have equal nonzero length")
        if any(b <= a for a, b in zip(self.raw_scores, self.raw_scores[1:])):
            raise ValueError(f"{self.name}: raw scores must be strictly increasing")
        if any(f < 0 or not math.isfinite(f) for f in self.frequencies) or sum(self.frequencies) <= 1:
            raise ValueError(f"{self.name}: frequencies must be finite, nonnegative, and total above 1")
        if any(isinstance(value, bool) or int(value) != value for value in self.empirical_scores):
            raise ValueError(f"{self.name}: empirical scores must be integers")


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


def weighted_stats(scores: Sequence[int], frequencies: Sequence[float]) -> tuple[float, float]:
    n = sum(frequencies)
    total = sum(f * x for f, x in zip(frequencies, scores))
    total_sq = sum(f * x * x for f, x in zip(frequencies, scores))
    variance = (total_sq - total * total / n) / (n - 1)
    return total / n, math.sqrt(max(0.0, variance))


def solve_curve(problem: CurveProblem, config: SolverConfig) -> CurveSolution:
    problem.validate()
    if config.frequency_scale <= 0:
        raise ValueError("frequency_scale must be positive")
    if config.score_min > config.score_max:
        raise ValueError("score_min cannot exceed score_max")
    if config.fixed_first is not None and not config.score_min <= config.fixed_first <= config.score_max:
        raise ValueError("fixed_first is outside score bounds")
    if config.fixed_last is not None and not config.score_min <= config.fixed_last <= config.score_max:
        raise ValueError("fixed_last is outside score bounds")
    if config.max_step < 0 or config.mean_tolerance < 0:
        raise ValueError("max_step and mean_tolerance must be nonnegative")
    if config.sd_min < 0 or config.sd_min > config.sd_max:
        raise ValueError("SD bounds are invalid")
    if config.time_limit_seconds <= 0 or config.workers <= 0:
        raise ValueError("time limit and workers must be positive")
    model = cp_model.CpModel()
    weights = [max(0, round(f * config.frequency_scale)) for f in problem.frequencies]
    n = sum(weights)
    scores = [model.new_int_var(config.score_min, config.score_max, f"score_{r}") for r in range(len(problem.raw_scores))]
    squares = [model.new_int_var(config.score_min**2, config.score_max**2, f"square_{r}") for r in range(len(scores))]
    square_table = [(x, x * x) for x in range(config.score_min, config.score_max + 1)]
    for score, square in zip(scores, squares):
        model.add_allowed_assignments([score, square], square_table)
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
    model.add(weighted_sum_sq == sum(w * x for w, x in zip(weights, squares)))
    target_sum = round(config.target_mean * n)
    tolerance = round(config.mean_tolerance * n)
    model.add(weighted_sum >= target_sum - tolerance)
    model.add(weighted_sum <= target_sum + tolerance)

    weighted_sum_squared = model.new_int_var((n * config.score_min) ** 2, (n * config.score_max) ** 2, "weighted_sum_squared")
    model.add_multiplication_equality(weighted_sum_squared, [weighted_sum, weighted_sum])
    variance_numerator = model.new_int_var(0, config.score_max**2 * n * n, "variance_numerator")
    model.add(variance_numerator == n * weighted_sum_sq - weighted_sum_squared)
    denominator = n * (n - config.frequency_scale)
    variance_scale = 100
    model.add(variance_scale * variance_numerator >= round(config.sd_min**2 * variance_scale) * denominator)
    model.add(variance_scale * variance_numerator <= round(config.sd_max**2 * variance_scale) * denominator)

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
    for row in range(1, len(scores) - 1):
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
    result = [solver.value(score) for score in scores]
    mean, sd = weighted_stats(result, problem.frequencies)
    return CurveSolution(
        problem.name, status_name, elapsed, solver.objective_value, result, mean, sd,
        sum(x != y for x, y in zip(result, problem.empirical_scores)),
        sum(abs(x - y) for x, y in zip(result, problem.empirical_scores)),
        sum(f * abs(x - y) for f, x, y in zip(problem.frequencies, result, problem.empirical_scores)),
        sum(abs(result[r + 1] - 2 * result[r] + result[r - 1]) for r in range(1, len(result) - 1)),
    )


MAIN_NS = "http://schemas.openxmlformats.org/spreadsheetml/2006/main"
REL_NS = "http://schemas.openxmlformats.org/officeDocument/2006/relationships"
PKG_REL_NS = "http://schemas.openxmlformats.org/package/2006/relationships"


def worksheet_part(archive: ZipFile, sheet_name: str) -> str:
    root = ElementTree.fromstring(archive.read("xl/workbook.xml"))
    sheet = root.find(f".//{{{MAIN_NS}}}sheet[@name='{sheet_name}']")
    if sheet is None:
        raise ValueError(f"Workbook does not contain output sheet {sheet_name!r}")
    rel_id = sheet.attrib[f"{{{REL_NS}}}id"]
    rels = ElementTree.fromstring(archive.read("xl/_rels/workbook.xml.rels"))
    rel = rels.find(f".//{{{PKG_REL_NS}}}Relationship[@Id='{rel_id}']")
    if rel is None:
        raise ValueError(f"Cannot resolve worksheet relationship {rel_id}")
    target = rel.attrib["Target"].replace("\\", "/")
    return target.lstrip("/") if target.startswith("/") else str(PurePosixPath("xl") / target)


def replace_numeric_cell(xml: str, reference: str, value: int) -> str:
    pattern = re.compile(rf'(<c\b(?=[^>]*\br="{re.escape(reference)}")[^>]*>.*?<v>)(.*?)(</v>)', re.DOTALL)
    updated, count = pattern.subn(rf"\g<1>{int(value)}\g<3>", xml, count=1)
    if count != 1:
        raise ValueError(f"Could not locate numeric cell {reference}")
    return updated


def force_recalculation(xml: str) -> str:
    match = re.search(r"<calcPr\b[^>]*/>", xml)
    if match is None:
        return xml
    calc = match.group(0)
    for name, value in {"calcMode": "auto", "fullCalcOnLoad": "1", "forceFullCalc": "1"}.items():
        if re.search(rf'\b{name}="[^"]*"', calc):
            calc = re.sub(rf'\b{name}="[^"]*"', f'{name}="{value}"', calc)
        else:
            calc = calc[:-2] + f' {name}="{value}"/>'
    return xml[:match.start()] + calc + xml[match.end():]


def write_workbook(source: Path, destination: Path, sheet_name: str, solutions: list[CurveSolution]) -> None:
    with ZipFile(source, "r") as source_zip:
        part = worksheet_part(source_zip, sheet_name)
        sheet_xml = source_zip.read(part).decode("utf-8")
        for column_index, solution in enumerate(solutions, start=2):
            if solution.scores is None:
                raise ValueError(f"Cannot write unsolved curve {solution.name}")
            column = chr(ord("A") + column_index - 1)
            for row_index, score in enumerate(solution.scores, start=2):
                sheet_xml = replace_numeric_cell(sheet_xml, f"{column}{row_index}", score)
        workbook_xml = force_recalculation(source_zip.read("xl/workbook.xml").decode("utf-8"))
        destination.parent.mkdir(parents=True, exist_ok=True)
        with ZipFile(destination, "w", ZIP_DEFLATED, compresslevel=6) as output_zip:
            for info in source_zip.infolist():
                payload = source_zip.read(info.filename)
                if info.filename == part:
                    payload = sheet_xml.encode("utf-8")
                elif info.filename == "xl/workbook.xml":
                    payload = workbook_xml.encode("utf-8")
                target = ZipInfo(info.filename, date_time=info.date_time)
                for attr in ("compress_type", "comment", "extra", "internal_attr", "external_attr", "create_system", "flag_bits"):
                    setattr(target, attr, getattr(info, attr))
                output_zip.writestr(target, payload)


def load_part_a(path: Path) -> tuple[dict, list[CurveProblem]]:
    payload = json.loads(path.read_text(encoding="utf-8"))
    if payload.get("schema") != "handsmoothing.part_a.v2":
        raise ValueError(f"Unsupported or missing Part A schema in {path}")
    problems = [CurveProblem(
        str(item["name"]),
        [int(x) for x in item["raw_scores"]],
        [int(x) for x in item["empirical_scores"]],
        [float(x) for x in item["frequencies"]],
    ) for item in payload.get("problems", [])]
    if not problems:
        raise ValueError("Part A artifact contains no curve problems")
    reference_raw = list(problems[0].raw_scores)
    if any(list(problem.raw_scores) != reference_raw for problem in problems[1:]):
        raise ValueError("Part A curve problems must use the same raw-score grid")
    return payload, problems


def file_sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for block in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def historical_comparisons(
    problems: list[CurveProblem], solutions: list[CurveSolution], historical: list[list[int]]
) -> list[dict]:
    if len(historical) != len(problems):
        raise ValueError("Historical curve count does not match the problem count")
    comparisons = []
    for problem, solution, benchmark in zip(problems, solutions, historical):
        if len(benchmark) != len(problem.raw_scores):
            raise ValueError(f"Historical row count differs for {problem.name}")
        if solution.scores is None:
            comparisons.append({"name": problem.name, "available": False})
            continue
        differences = [actual - expected for actual, expected in zip(solution.scores, benchmark)]
        comparisons.append({
            "name": problem.name,
            "available": True,
            "exact_match_cells": sum(value == 0 for value in differences),
            "changed_cells": sum(value != 0 for value in differences),
            "mean_absolute_difference": sum(abs(value) for value in differences) / len(differences),
            "maximum_absolute_difference": max(abs(value) for value in differences),
            "signed_differences_by_raw_score": dict(zip(map(str, problem.raw_scores), differences)),
        })
    return comparisons


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Handsmoothing Optimization Part B")
    parser.add_argument("--prep-file", type=Path, help="Override configured Part A JSON artifact")
    parser.add_argument("--output-dir", type=Path, help="Override configured Part B output directory")
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    prep_path = args.prep_file or (Path(PART_A_OVERRIDE) if PART_A_OVERRIDE else PART_A_FILE)
    output_dir = args.output_dir or (Path(OUTPUT_OVERRIDE) if OUTPUT_OVERRIDE else OUTPUT_DIR)
    if not prep_path.is_file():
        raise FileNotFoundError(f"Run Part A first; artifact not found: {prep_path}")
    payload, problems = load_part_a(prep_path)
    source = Path(str(payload["source_workbook"]))
    expected_hash = payload.get("source_fingerprints", {}).get("benchmark_sha256")
    if not source.is_file():
        raise FileNotFoundError(source)
    if expected_hash and file_sha256(source) != expected_hash:
        raise ValueError("Historical benchmark workbook changed after Part A; rerun Part A")
    config = SolverConfig()
    solutions = [solve_curve(problem, config) for problem in problems]
    all_solved = all(solution.scores is not None for solution in solutions)
    historical = [[int(value) for value in row] for row in payload.get("historical_scores", [])]
    comparisons = historical_comparisons(problems, solutions, historical)
    output_dir.mkdir(parents=True, exist_ok=True)
    report = {
        "source_workbook": payload.get("source_workbook"),
        "dataprep_file": str(prep_path.resolve()),
        "workbook_layout": payload.get("workbook_layout"),
        "empirical_score_source": payload.get("empirical_score_source"),
        "reconstruction": payload.get("reconstruction"),
        "source_fingerprints": payload.get("source_fingerprints"),
        "source_comparisons": payload.get("source_comparisons"),
        "configuration": asdict(config),
        "all_solved": all_solved,
        "solutions": [asdict(solution) for solution in solutions],
        "historical_comparisons": comparisons,
    }
    (output_dir / "solution_report.json").write_text(json.dumps(report, indent=2), encoding="utf-8")
    with (output_dir / "optimized_scores.csv").open("w", newline="", encoding="utf-8-sig") as handle:
        writer = csv.writer(handle)
        writer.writerow(["raw_score", *[problem.name for problem in problems]])
        for row, raw_score in enumerate(problems[0].raw_scores):
            writer.writerow([raw_score, *[(solution.scores or [""] * len(problems[0].raw_scores))[row] for solution in solutions]])
    with (output_dir / "curve_comparison.csv").open("w", newline="", encoding="utf-8-sig") as handle:
        writer = csv.writer(handle)
        writer.writerow(["group", "raw_score", "reconstructed_initial", "optimized", "historical_final", "optimized_minus_historical"])
        for group, (problem, solution, benchmark) in enumerate(zip(problems, solutions, historical), start=1):
            for row, raw_score in enumerate(problem.raw_scores):
                optimized = "" if solution.scores is None else solution.scores[row]
                difference = "" if solution.scores is None else solution.scores[row] - benchmark[row]
                writer.writerow([f"ss{group}", raw_score, problem.empirical_scores[row], optimized, benchmark[row], difference])
    if all_solved:
        write_workbook(source, output_dir / OUTPUT_WORKBOOK_NAME, str(payload.get("output_sheet", "Hdsmth")), solutions)

    print("Handsmoothing Optimization Part B")
    print(f"Part A input: {prep_path}")
    for solution, comparison in zip(solutions, comparisons):
        stats = "" if solution.scores is None else f" mean={solution.weighted_mean:.3f} sd={solution.weighted_sd:.3f} changed_from_initial={solution.changed_cells}"
        historical_stats = "" if not comparison.get("available") else f" changed_from_historical={comparison['changed_cells']}"
        print(f"{solution.name}: {solution.status} ({solution.solve_seconds:.3f}s){stats}{historical_stats}")
    print(f"All curves solved: {all_solved}")
    print(f"Outputs: {output_dir}")
    if not all_solved:
        raise SystemExit(2)


if __name__ == "__main__":
    main()
