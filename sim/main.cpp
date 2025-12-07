#include "Vverilator_top.h"
#include "verilated.h"
#include "verilated_vcd_c.h"

#include <cstdio>
#include <cstdint>
#include <memory>

static vluint64_t sim_time = 0;

static double sc_time_stamp() { return sim_time; }

int main(int argc, char **argv) {
    Verilated::commandArgs(argc, argv);
    if (false && argc) {}

    std::unique_ptr<Vverilator_top> top{new Vverilator_top};

    VerilatedVcdC *tfp = nullptr;
    bool trace = Verilated::gotFinish();
    if (trace) {
        Verilated::traceEverOn(true);
        tfp = new VerilatedVcdC;
        top->trace(tfp, 99);
        tfp->open("waveform.vcd");
    }

    while (!Verilated::gotFinish() && sim_time < 100000) {
        top->clk = sim_time & 1;
        top->eval();

        if (tfp)
            tfp->dump(sim_time);

        sim_time++;
    }

    if (tfp) {
        tfp->close();
        delete tfp;
    }

    top->final();
    return 0;
}
