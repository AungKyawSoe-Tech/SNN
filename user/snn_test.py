#!/usr/bin/env python3
"""Simple user-space harness to exercise the LiteX SNN accelerator CSR interface."""

import argparse
import mmap
import os
import struct
import time

CTRL_OFFSET = 0x00
STATUS_OFFSET = 0x04
EPOCH_LEN_OFFSET = 0x08
NEURON_COUNT_OFFSET = 0x0C
IRQ_STATUS_OFFSET = 0x24
SPIKE_IN_LEVEL_OFFSET = 0x28
SPIKE_OUT_LEVEL_OFFSET = 0x2C

WORD_SIZE = 4


def write_reg(mem, offset, value):
    mem[offset:offset + WORD_SIZE] = struct.pack("<I", value)


def read_reg(mem, offset):
    return struct.unpack("<I", mem[offset:offset + WORD_SIZE])[0]


def main():
    parser = argparse.ArgumentParser(description="SNN accelerator smoke test")
    parser.add_argument("--csr", default="/dev/mem", help="Path to CSR-mapped device")
    parser.add_argument("--base", type=lambda x: int(x, 0), required=True, help="Physical base address of CSR block")
    parser.add_argument("--size", type=lambda x: int(x, 0), default=0x1000, help="Mapping window size")
    args = parser.parse_args()

    fd = os.open(args.csr, os.O_RDWR | os.O_SYNC)
    try:
        mem = mmap.mmap(fd, args.size, mmap.MAP_SHARED, mmap.PROT_READ | mmap.PROT_WRITE, offset=args.base)
        try:
            write_reg(mem, CTRL_OFFSET, 0x2)  # reset
            time.sleep(0.01)
            write_reg(mem, CTRL_OFFSET, 0x1)  # enable
            write_reg(mem, EPOCH_LEN_OFFSET, 1000)
            write_reg(mem, NEURON_COUNT_OFFSET, 256)

            print(f"status=0x{read_reg(mem, STATUS_OFFSET):08x}")
            print(f"spike_in_level={read_reg(mem, SPIKE_IN_LEVEL_OFFSET)}")
            print(f"spike_out_level={read_reg(mem, SPIKE_OUT_LEVEL_OFFSET)}")

            irq_status = read_reg(mem, IRQ_STATUS_OFFSET)
            if irq_status:
                write_reg(mem, IRQ_STATUS_OFFSET, irq_status)
                print(f"cleared irq bits=0x{irq_status:08x}")
        finally:
            mem.close()
    finally:
        os.close(fd)


if __name__ == "__main__":
    main()
