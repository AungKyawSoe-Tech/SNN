# Timing and Utilization Iteration Plan

## Goals
Outline the feedback loop for monitoring timing closure and FPGA resource usage while integrating the SNN accelerator with the LiteX SoC.

## Metrics to Track
- Post-route WNS/TNS at 100 MHz system clock
- LUT, FF, BRAM, DSP utilization vs. Artix-7 device limits
- Clock domain crossing reports for accelerator/SoC boundaries
- Power estimates from Vivado power analyzer

## Iteration Steps
1. **Baseline Build**: Synthesize LiteX SoC without accelerator to capture baseline resource/timing numbers.
2. **Incremental Integration**: Add accelerator components feature by feature (CSRs, FIFOs, DMA, compute core) and record deltas.
3. **Constraint Refinement**: Update XDC constraints for generated clocks, false paths, and multicycle paths introduced by accelerator logic.
4. **Floorplanning (if required)**: Reserve Pblocks for accelerator memories and routing-heavy sections to aid congestion control.
5. **Timing Debug**: Use Vivado timing reports and `report_timing_summary` to locate critical paths, adjust pipeline stages or placement constraints accordingly.
6. **Resource Budgeting**: Maintain spreadsheet/log of utilization trend per build to ensure headroom for future features.
7. **Regression Automation**: Script nightly builds via CI to capture timing/utilization drift after RTL or driver changes.

## Tooling
- Vivado Tcl scripts (`run.tcl`) capturing synth/impl/report commands
- Python-based parsers to ingest report_utilization/report_timing for dashboards
- LiteX build hooks to trigger post-build report extraction

## Exit Criteria
- WNS >= 0.5 ns at 100 MHz with accelerator enabled
- LUT utilization < 80%, BRAM utilization < 75%
- No critical warnings in CDC or power analysis
- Automated report artifacts stored with build logs for traceability
