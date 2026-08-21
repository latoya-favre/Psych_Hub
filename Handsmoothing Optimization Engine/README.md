# Handsmoothing Optimization Engine

An initial CP-SAT engine for smoothing integer raw-score-to-scaled-score norm
curves subject to statistical and editorial constraints.

## Current capabilities

- Reads the WAIS MR workbook layout (`Hdsmth`, `freq`, and `dif` sheets).
- Reads the WAIS VC norm-development layout (`handsmoothed` and `freq`
  sheets), including its 46 raw-score rows.
- Optimizes each norm group independently.
- Enforces integer scaled scores, fixed endpoints, monotonicity, maximum raw-score
  step size, weighted-mean bounds, and weighted-SD bounds.
- Minimizes frequency-weighted changes from the empirical curve, with secondary
  penalties for the number of changed cells and local roughness.
- Writes an auditable JSON report, a solution CSV, and a fully formatted Excel
  workbook without modifying the input template.
- Preserves the template's formulas, styles, conditional formatting, widths,
  fills, borders, and QA sheets by changing only `Hdsmth!B2:N28`.

This is the first engine slice. Cross-group constraints and direct workbook output
will be added after the marginal-curve behavior is calibrated.

For VC workbooks, no separate pre-smoothed scaled-score grid has been identified.
The current VC path is therefore a reconstruction benchmark: it uses the final
`handsmoothed` curves as the fidelity targets and reports any changes required to
satisfy the configured CP-SAT constraints. This choice is recorded in the Part A
artifact as `empirical_score_source=manual_scores_reconstruction_benchmark`.

## Setup

```powershell
python -m venv .venv
.venv\Scripts\python -m pip install -e .
```

## Run the WAIS MR prototype (Part A + Part B)

```powershell
.venv\Scripts\soe `
  "C:\Users\UFAVRLA\PythonProjects\HandSmoothing_WAIS5\Data\WAIS_MR_HandSmoothing.xlsx" `
  --output-dir outputs\wais_mr
```

Use `soe --help` for constraint and objective options.

## SOE-style staged workflow

The CLI now supports explicit stages:

- `--part A`: initial dataprep (reads workbook and writes a prep artifact)
- `--part B`: CP-SAT run from an existing prep artifact
- `--part AB` (default): runs Part A then Part B

Part A only:

```powershell
.venv\Scripts\soe data\WISC5\WISC5_fake_HandSmoothing.xlsx --part A --output-dir outputs\wisc5_parted
```

Part B only:

```powershell
.venv\Scripts\soe --part B --output-dir outputs\wisc5_parted
```

By default the dataprep file is written to:

- `outputs\...\part_a_dataprep.json`

Use `--prep-file` to override that path.

The run creates three outputs:

- `solution_report.json`
- `optimized_scores.csv`
- `optimized_handsmoothing.xlsx`

## Synthetic WISC5 practice workbook

Generate a fake workbook for handsmoothing exercises with:

```powershell
python python_scripts\create_fake_wisc5_dataset.py
```

This writes `data\WISC5\WISC5_fake_HandSmoothing.xlsx` with the same `Hdsmth`, `freq`, and `dif`
sheet layout expected by the current CLI, plus a short note sheet marking it as synthetic data.
