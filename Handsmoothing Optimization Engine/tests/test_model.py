from handsmoothing_soe.model import CurveProblem, SolverConfig, solve_curve


def test_solver_returns_monotonic_bounded_curve() -> None:
    problem = CurveProblem(
        name="synthetic",
        raw_scores=list(range(10)),
        empirical_scores=[1, 2, 4, 6, 8, 11, 13, 15, 17, 19],
        frequencies=[1, 2, 4, 8, 12, 12, 8, 4, 2, 1],
    )
    config = SolverConfig(
        target_mean=10,
        mean_tolerance=1.0,
        sd_min=3.0,
        sd_max=6.0,
        max_step=3,
        time_limit_seconds=2,
    )
    solution = solve_curve(problem, config)
    assert solution.scores is not None
    assert solution.scores[0] == 1
    assert solution.scores[-1] == 19
    assert all(a <= b for a, b in zip(solution.scores, solution.scores[1:]))
    assert all(b - a <= 3 for a, b in zip(solution.scores, solution.scores[1:]))


def test_problem_rejects_non_increasing_raw_scores() -> None:
    problem = CurveProblem("bad", [0, 1, 1], [1, 2, 3], [2, 2, 2])
    try:
        problem.validate()
    except ValueError as exc:
        assert "strictly increasing" in str(exc)
    else:
        raise AssertionError("Expected validation failure")


def test_solver_accepts_norm_sample_of_180() -> None:
    problem = CurveProblem(
        name="n180",
        raw_scores=list(range(46)),
        empirical_scores=[min(19, 1 + raw_score * 18 // 45) for raw_score in range(46)],
        frequencies=[4] * 45 + [0],
    )
    config = SolverConfig(mean_tolerance=2.0, sd_min=2.0, sd_max=6.0, time_limit_seconds=2)

    solution = solve_curve(problem, config)

    assert solution.status in {"OPTIMAL", "FEASIBLE"}
    assert solution.scores is not None
