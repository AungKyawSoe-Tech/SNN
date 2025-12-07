# WP01: RISC-V Core Assessment

## Objectives
- Catalogue the existing VHDL RISC-V core (target: NEORV32), its pipeline structure, and extension hooks.
- Verify RV32IMAC compliance to ensure Linux compatibility.
- Identify custom opcode space reserved for SNN extensions.

## Deliverables
1. Core feature matrix (ISA coverage, privilege levels, pipeline characteristics).
2. Compliance test plan leveraging riscv-arch-test and custom diagnostics.
3. Opcode allocation document highlighting available major opcodes (0x0B, 0x2B, etc.).
4. Gap report with remediation actions and owners.

## Work Breakdown
### Task 1: Source Inventory
- Locate VHDL repositories (git submodules or external links). Candidate: https://github.com/stnolting/neorv32.
- Record commit hashes, licensing, and maintenance status.
- Note dependency on vendor primitives or generics.
- Current import: commit `cfcfda82a07a5cc20a2d7ec6` (depth-1 clone on 2025-11-29) stored at `rtl/neorv32`.

### Task 2: ISA Coverage Review
- Inspect decode logic (`rtl/core/neorv32_cpu.vhd`) to confirm presence of RV32I base instructions.
- Verify optional extensions: M (mul/div), A (atomics), C (compressed), GPR CSR handling.
- Document CSR map (mstatus, medeleg, satp, etc.).

### Task 3: Compliance Testing Strategy
- Set up `riscv-arch-test` harness with Verilator/Questa.
- Define simulation configuration (memory map, MMU enablement, trap vector).
- Plan for automation via `pytest` or `ctest` wrappers.

### Task 4: Custom Opcode Mapping
- Extract decode case statements from `rtl/core/neorv32_cpu/decode/neorv32_cpu_control.vhd` to list used major/opcode fields.
- Highlight available slots; propose reserving `custom-0` (0x0B) for SNN instructions.
- Outline process to add new instructions without disrupting existing pipeline.

### Task 5: Risk Assessment
- Evaluate timing slack from previous builds (if available).
- Identify missing features required by Linux (e.g., `satp`, `sfence.vma`).
- Prioritise fixes with target milestones.

## Documentation Artifacts
- `docs/wp01/core_matrix.xlsx` (to be created post-inventory).
- `docs/wp01/compliance_plan.md` (future deliverable).
- `docs/wp01/opcode_map.csv` (future deliverable).

## Next Actions
1. Gather VHDL source links from internal repos or upstream.
2. Produce initial feature matrix template.
3. Spin up simulation environment once toolchain is verified (see Environment Setup Guide).
