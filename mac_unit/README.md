# MAC unit files

- `mac.v`: signed multiply-accumulate RTL.
- `tb_mac.v`: directed and randomized self-checking testbench.
- `failed_results.txt` and `corrected_results.txt`: summaries of the simulation outputs provided.
- [`synthesis_report.md`](synthesis_report.md): Vivado 2025.2 synthesis report for `xc7z020clg400-1`.

Run the simulation from this directory with Icarus Verilog:

```sh
iverilog -Wall -g2012 -o mac_sim mac.v tb_mac.v
vvp mac_sim
```

The testbench writes `mac.vcd` in the current working directory for waveform inspection. The waveform screenshot mentioned in the conversation could not be committed from the inline image display; upload it as a file (for example, `waveform.png`) and it can be added here.
