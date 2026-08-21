param(
    [Parameter(Mandatory = $true)][string]$Project,
    [Parameter(Mandatory = $true)][string]$Action,
    [Parameter(Mandatory = $true, ValueFromRemainingArguments = $true)][string[]]$Files,
    [string]$Notes = ""
)

$python = Join-Path $PSScriptRoot "..\.venv\Scripts\python.exe"
if (-not (Test-Path -LiteralPath $python)) {
    $python = "python"
}

& $python (Join-Path $PSScriptRoot "project_audit.py") log `
    --project $Project --action $Action --notes $Notes -- @Files
exit $LASTEXITCODE
