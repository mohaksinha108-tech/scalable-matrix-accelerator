MAC unit files
===============

- `mac.v`: signed multiply-accumulate RTL.
- `tb_mac.v`: directed and randomized self-checking testbench.
- `failed_results.txt` and `corrected_results.txt`: summaries of the simulation runs.

Run from this directory with Icarus Verilog:

```sh
iverilog -Wall -g2012 -o mac_sim mac.v tb_mac.v
vvp mac_sim
```

The testbench writes `mac.vcd` in the current working directory for waveform inspection.
