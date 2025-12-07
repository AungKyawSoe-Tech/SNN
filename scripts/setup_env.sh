#!/usr/bin/env bash
# Bootstrap LiteX/SNN environment inside WSL (Ubuntu 22.04 expected)
set -euo pipefail

sudo apt update
sudo apt install -y build-essential git python3 python3-venv python3-pip verilator gtkwave ghdl ghdl-yosys-plugin cmake ninja-build libffi-dev libssl-dev device-tree-compiler

if [ ! -d "$HOME/riscv" ]; then
  git clone https://github.com/riscv/riscv-gnu-toolchain.git "$HOME/riscv-gnu-toolchain"
  pushd "$HOME/riscv-gnu-toolchain"
  ./configure --prefix="$HOME/riscv" --enable-multilib
  make linux -j"$(nproc)"
  popd
fi

echo 'export PATH=$HOME/riscv/bin:$PATH' >> "$HOME/.bashrc"

git clone https://github.com/enjoy-digital/litex.git "$HOME/litex"
pushd "$HOME/litex"
git submodule update --init --recursive
python3 -m venv "$HOME/envs/snn"
source "$HOME/envs/snn/bin/activate"
pip install -r litex_setup/requirements.txt
pip install numpy matplotlib websockets pyzmq pytest
./litex_setup.py init
./litex_setup.py install
 deactivate
popd

echo "Environment setup complete. Activate via 'source ~/envs/snn/bin/activate'."
