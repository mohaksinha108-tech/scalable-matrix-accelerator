MAC unit files
===============

- `design.sv`: signed multiply-accumulate RTL.
- `testbench.sv`: directed and randomized self-checking testbench.
- `failed_results.txt` and `corrected_results.txt`: summaries of the two simulation outputs provided.

Run from this directory with Icarus Verilog:

```sh
iverilog -Wall -g2012 -o mac_sim design.sv testbench.sv
vvp mac_sim
```

The testbench writes `mac.vcd` in the current working directory for waveform inspection.
