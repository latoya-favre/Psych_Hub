"""Desktop entry point for the Stratification Optimization Engine."""
import sys
import traceback
from datetime import datetime
from pathlib import Path

from gui import OptimizationGUI


def app_dir():
    return Path(sys.executable).parent if getattr(sys, "frozen", False) else Path(__file__).resolve().parent


def self_test():
    """Verify packaged native dependencies without running an optimization."""
    import pandas  # noqa: F401
    import pyreadstat  # noqa: F401
    from ortools.sat.python import cp_model  # noqa: F401
    return 0


if __name__ == "__main__":
    if "--self-test" in sys.argv:
        raise SystemExit(self_test())
    logs = app_dir() / "logs"
    logs.mkdir(exist_ok=True)
    try:
        OptimizationGUI()
    except Exception:
        (logs / f"crash_{datetime.now():%Y%m%d_%H%M%S}.log").write_text(traceback.format_exc(), encoding="utf-8")
        raise
