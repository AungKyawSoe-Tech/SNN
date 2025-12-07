# Dry-Run Plan for LiteX Baseline Build

## Purpose
Exercise `scripts/build_baseline.ps1` / `scripts/build_baseline.sh` in dry-run mode to verify logging/archival without consuming Vivado licenses.

## Steps
1. Ensure LiteX repository is cloned at `%USERPROFILE%/litex` or override `-LiteXPath` / `--litex` options.
2. Run PowerShell script:
   ```pwsh
   pwsh scripts/build_baseline.ps1 -WithEthernet -WithSDCard -DryRun
   ```
3. Run Bash script (WSL):
   ```bash
   ./scripts/build_baseline.sh --dry-run
   ```
4. Confirm directory `reports/vivado/<timestamp>/` created.
5. Validate console output includes "Dry run enabled; skipping execution.".

## Next Execution
- Pending LiteX clone completion and environment setup.
- After successful dry run, remove `DryRun` flag to produce actual reports.
