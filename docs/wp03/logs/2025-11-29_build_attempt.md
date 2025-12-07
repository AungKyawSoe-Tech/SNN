# Baseline Build Attempt (2025-11-29)

## Command
```pwsh
pwsh scripts/build_baseline.ps1 -LiteXPath "c:\CoPilot_Cli\SNN\third_party\litex" -WithEthernet -WithSDCard
```

## Outcome
- Failure: `ModuleNotFoundError: No module named 'litex_boards'`
- Reports directory `reports/vivado/20251201_200759` created but empty (dry logging only).

## Diagnosis
- Python environment does not yet have LiteX packages installed.
- Need to run `./litex_setup.py init` and `./litex_setup.py install` inside the LiteX clone or install via pip (`pip install litex` plus board dependencies).
- Ensure Python path includes `third_party/litex` or install as editable package.

## Next Actions
1. Activate project virtual environment.
2. From `third_party/litex`, execute `./litex_setup.py init` then `./litex_setup.py install`.
3. Re-run `scripts/build_baseline.ps1` without `-DryRun`.
4. Verify Vivado availability; once build succeeds, capture generated reports in `reports/vivado/<timestamp>/`.
