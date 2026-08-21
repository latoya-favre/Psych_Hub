# Project audit trail

`project_audit.xlsx` is the formatted, filterable audit workbook. Each logging
command also appends the same record to `project_audit.csv`, which is the simple,
portable backup.

Close the Excel workbook before logging. From the repository root, run:

```powershell
.\project_audit\audit.ps1 -Project CELF6 -Action Scored "C:\path\raw_dataset.sas7bdat"
```

Log several converted files in one command:

```powershell
.\project_audit\audit.ps1 -Project CELF6 -Action "Converted to Excel" `
  "C:\path\scored_ages_5_8.xlsx" "C:\path\scored_ages_9_12.xlsx"
```

Optional notes can record a program, version, run ID, or unusual decision:

```powershell
.\project_audit\audit.ps1 -Project CELF6 -Action Validated -Notes "All QA checks passed" `
  "C:\path\scored_all.xlsx"
```

The timestamp is generated automatically in local time, including its UTC
offset. One row is created per file.
