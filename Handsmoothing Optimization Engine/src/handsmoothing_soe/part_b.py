from __future__ import annotations

import csv
from dataclasses import asdict
import json
from pathlib import Path

from .model import CurveProblem, CurveSolution, SolverConfig, solve_curve
from .part_a import payload_to_problems
from .template_output import write_template_workbook


def write_solution_outputs(
    *,
    output_dir: Path,
    output_workbook_name: str,
    source_workbook: Path | None,
    output_sheet: str,
    config: SolverConfig,
    prep_path: Path,
    problems: list[CurveProblem],
    solutions: list[CurveSolution],
) -> bool:
    output_dir.mkdir(parents=True, exist_ok=True)
    all_solved = all(solution.scores is not None for solution in solutions)
    report = {
        "source_workbook": None if source_workbook is None else str(source_workbook),
        "dataprep_file": str(prep_path.resolve()),
        "configuration": asdict(config),
        "all_solved": all_solved,
        "solutions": [solution.to_dict() for solution in solutions],
    }
    (output_dir / "solution_report.json").write_text(json.dumps(report, indent=2), encoding="utf-8")

    with (output_dir / "optimized_scores.csv").open("w", newline="", encoding="utf-8-sig") as handle:
        writer = csv.writer(handle)
        writer.writerow(["raw_score", *[problem.name for problem in problems]])
        for row, raw_score in enumerate(problems[0].raw_scores):
            writer.writerow([raw_score, *[solution.scores[row] if solution.scores else "" for solution in solutions]])

    output_workbook = None
    if all_solved and source_workbook is not None and source_workbook.is_file():
        output_workbook = write_template_workbook(
            source_workbook,
            output_dir / output_workbook_name,
            solutions,
            sheet_name=output_sheet,
        )

    for solution in solutions:
        stats = "" if solution.scores is None else f" mean={solution.weighted_mean:.3f} sd={solution.weighted_sd:.3f} changed={solution.changed_cells}"
        print(f"{solution.name}: {solution.status} ({solution.solve_seconds:.3f}s){stats}")
    print(f"Wrote {output_dir / 'solution_report.json'}")
    print(f"Wrote {output_dir / 'optimized_scores.csv'}")
    if output_workbook is not None:
        print(f"Wrote {output_workbook}")
    elif all_solved:
        print("Skipped optimized workbook output because source workbook was unavailable.")
    return all_solved


def run_part_b(
    *,
    payload: dict,
    prep_path: Path,
    config: SolverConfig,
    output_dir: Path,
    output_workbook_name: str,
) -> bool:
    problems = payload_to_problems(payload)
    solutions = [solve_curve(problem, config) for problem in problems]
    source_workbook_value = payload.get("source_workbook")
    source_workbook = Path(source_workbook_value) if isinstance(source_workbook_value, str) else None
    output_sheet = str(payload.get("output_sheet", "Hdsmth"))
    return write_solution_outputs(
        output_dir=output_dir,
        output_workbook_name=output_workbook_name,
        source_workbook=source_workbook,
        output_sheet=output_sheet,
        config=config,
        prep_path=prep_path,
        problems=problems,
        solutions=solutions,
    )
