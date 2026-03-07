# RISC-V Web CPU Runner

🔗 Live Application:
https://risc-v-server-1.onrender.com/

## Overview

This project implements a 32-bit RV32I pipelined RISC-V processor in Verilog and a web-based interface that allows users to write assembly code, assemble it automatically, and run simulations.

The goal of the project is to demonstrate how a pipelined processor works, including data hazard resolution, forwarding, branch handling, and memory operations, while providing an easy way to test programs through a web interface.

![Pipeline Architecture](images/schema.png)

## Features
### Processor Architecture
- 32-bit RV32I instruction set subset
- 5-stage pipeline architecture (IF, ID, EX, MEM, WB)
- Implemented in Verilog HDL

### Supported Instructions
- R-type: add, and, or
- I-type: addi, lw
- S-type: sw
- B-type: beq


### Pipeline Hazard Handling

The processor includes hardware mechanisms to handle common pipeline hazards.

- Data Hazards: resolved using forwarding  from later pipeline stages.
- Load-Use Hazard: detected using a Hazard Detection Unit, which inserts a pipeline stall when needed.
- Control Hazards: branch instructions are resolved using branch decision in the Execute stage and pipeline flush when a branch is taken

## Project Components
- Verilog Processor
- Custom RISC-V Assembler (Python)
- Web Simulato