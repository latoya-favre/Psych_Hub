from __future__ import annotations

import argparse
from pathlib import Path

from .model import SolverConfig
from .part_a import load_part_a_payload, resolve_prep_path, run_part_a
from .part_b import run_part_b


def _parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="SOE-style handsmoothing with Part A dataprep and Part B CP-SAT.")
    parser.add_argument("workbook", nargs="?", type=Path, help="Handsmoothing workbook (required for Part A)")
    parser.add_argument("--output-dir", type=Path, default=Path("outputs/latest"))
    parser.add_argument(
        "--part",
        choices=["A", "B", "AB"],
        default="AB",
        help="Run Part A (dataprep), Part B (CP-SAT), or AB (both)",
    )
    parser.add_argument(
        "--prep-file",
        type=Path,
        default=None,
        help="Path to Part A dataprep JSON (default: <output-dir>/part_a_dataprep.json)",
    )
    parser.add_argument(
        "--output-workbook-name",
        default="optimized_handsmoothing.xlsx",
        help="Filename for the template-preserving optimized workbook",
    )
    parser.add_argument("--mean-tolerance", type=float, default=0.30)
    parser.add_argument("--sd-min", type=float, default=2.70)
    parser.add_argument("--sd-max", type=float, default=3.30)
    parser.add_argument("--max-step", type=int, default=2)
    parser.add_argument("--time-limit", type=float, default=10.0, help="Seconds per curve")
    parser.add_argument("--workers", type=int, default=8)
    return parser


def main(argv: list[str] | None = None) -> int:
    args = _parser().parse_args(argv)
    prep_path = resolve_prep_path(args.prep_file, args.output_dir)

    if args.part in ("A", "AB") and args.workbook is None:
        raise SystemExit("A workbook path is required for Part A/AB runs.")
    if args.part == "B" and not prep_path.is_file():
        raise SystemExit(f"Part B requires a dataprep file. Not found: {prep_path}")

    part_a_payload = None
    if args.part in ("A", "AB"):
        assert args.workbook is not None
        part_a_payload = run_part_a(args.workbook, prep_path)
        print(f"Part A complete: wrote {prep_path}")
        if args.part == "A":
            return 0

    if part_a_payload is None:
        part_a_payload = load_part_a_payload(prep_path)

    config = SolverConfig(
        mean_tolerance=args.mean_tolerance,
        sd_min=args.sd_min,
        sd_max=args.sd_max,
        max_step=args.max_step,
        time_limit_seconds=args.time_limit,
        workers=args.workers,
    )
    all_solved = run_part_b(
        payload=part_a_payload,
        prep_path=prep_path,
        config=config,
        output_dir=args.output_dir,
        output_workbook_name=args.output_workbook_name,
    )
    return 0 if all_solved else 2


if __name__ == "__main__":
    raise SystemExit(main())
