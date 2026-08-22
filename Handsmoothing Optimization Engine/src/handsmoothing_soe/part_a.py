from __future__ import annotations

from datetime import datetime, timezone
import json
from pathlib import Path
from typing import Any

from .model import CurveProblem
from .wais_workbook import load_handsmoothing_workbook


PART_A_SCHEMA = "handsmoothing.part_a.v1"


def problem_to_dict(problem: CurveProblem) -> dict[str, Any]:
    return {
        "name": problem.name,
        "raw_scores": [int(value) for value in problem.raw_scores],
        "empirical_scores": [int(value) for value in problem.empirical_scores],
        "frequencies": [float(value) for value in problem.frequencies],
    }


def problem_from_dict(payload: dict[str, Any]) -> CurveProblem:
    return CurveProblem(
        name=str(payload["name"]),
        raw_scores=[int(value) for value in payload["raw_scores"]],
        empirical_scores=[int(value) for value in payload["empirical_scores"]],
        frequencies=[float(value) for value in payload["frequencies"]],
    )


def payload_to_problems(payload: dict[str, Any]) -> list[CurveProblem]:
    return [problem_from_dict(problem_payload) for problem_payload in payload["problems"]]


def default_prep_path(output_dir: Path) -> Path:
    return output_dir / "part_a_dataprep.json"


def resolve_prep_path(prep_file: Path | None, output_dir: Path) -> Path:
    return prep_file if prep_file is not None else default_prep_path(output_dir)


def run_part_a(workbook: Path, prep_path: Path) -> dict[str, Any]:
    source = load_handsmoothing_workbook(workbook)
    payload = {
        "schema": PART_A_SCHEMA,
        "prepared_at_utc": datetime.now(timezone.utc).isoformat(),
        "source_workbook": str(workbook.resolve()),
        "workbook_layout": source.workbook_layout,
        "output_sheet": source.output_sheet,
        "empirical_score_source": (
            "manual_scores_reconstruction_benchmark"
            if source.workbook_layout == "wais_vc"
            else "dif_sheet"
        ),
        "group_count": len(source.problems),
        "row_count": len(source.problems[0].raw_scores) if source.problems else 0,
        "problems": [problem_to_dict(problem) for problem in source.problems],
        "manual_scores": [[int(score) for score in row] for row in source.manual_scores],
    }
    prep_path.parent.mkdir(parents=True, exist_ok=True)
    prep_path.write_text(json.dumps(payload, indent=2), encoding="utf-8")
    return payload


def load_part_a_payload(prep_path: Path) -> dict[str, Any]:
    if not prep_path.is_file():
        raise FileNotFoundError(prep_path)
    payload = json.loads(prep_path.read_text(encoding="utf-8"))
    if payload.get("schema") != PART_A_SCHEMA:
        raise ValueError(f"Unsupported dataprep schema in {prep_path}")
    problems = payload.get("problems")
    if not isinstance(problems, list) or not problems:
        raise ValueError(f"Dataprep file {prep_path} has no problems")
    return payload
