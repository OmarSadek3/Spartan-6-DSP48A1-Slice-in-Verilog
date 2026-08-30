# Spartan-6 DSP48A1 Slice in Verilog

## Project Overview
This repository contains a structural Verilog implementation of the Xilinx Spartan-6 DSP48A1 slice. The design is configured as a hardware accelerator and verified with a dual-projectile interception system testbench that applies Euler integration.

## Features
* Structural RTL Design: Fully parameterized Verilog implementation of the DSP48A1 slice.
* Hardware Math Mapping: Computes kinematics directly using the Multiply-Accumulate (MAC) operation.
* Pipelined Architecture: Utilizes internal pipeline registers to maximize operating frequency.
* Automated Python Visualization: Parses the fixed-point output from ModelSim into a trajectory plot.

## Repository Structure
* `rtl/`: Contains the structural Verilog source files for the DSP48A1 slice and supporting modules.
* `tb/`: Contains the ModelSim testbench (`tb_projectile_motion.v`), the Python visualization script (`plot_projectile.py`), and the generated output text file (`collision_data.txt`).
* `docs/`: Contains the engineering documentation (`The_Math_Behind_the_Testbench.pdf`), the official Xilinx Spartan-6 DSP48A1 User Guide (`UG389.pdf`), and simulation assets.

## How to Run

### 1. Hardware Simulation (ModelSim)
1. Compile the files located in the `rtl/` and `tb/` directories using ModelSim.
2. Run the `tb_projectile_motion` testbench.
3. The testbench generates a `collision_data.txt` file containing the coordinates of the projectiles, which is automatically saved inside the `tb/` directory.

### 2. Data Visualization (Python)
Ensure `matplotlib` is installed:
```bash
pip install matplotlib
```
Navigate to the tb/ directory where both the Python script and the generated text file are located:
```
cd tb/
python plot_projectile.py
```
## Documentation
For a detailed mathematical breakdown of the kinematics, fixed-point scaling strategy, and the mapping of physical equations to the Verilog testbench, refer to `the_Math_behind_the_Testbench.pdf`. Additionally, the official Xilinx Spartan-6 DSP48A1 User Guide (`UG389.pdf`) is included in the `docs/` folder for architectural reference.
