# 🧮 MPI Parallel Matrix Multiplication — High-Performance Computing Topologies

[A punchy one-sentence summary: Accelerating large-scale matrix operations through distributed memory architectures and Message Passing Interface (MPI) topologies.]

[![C](https://img.shields.io/badge/C-00599C?style=for-the-badge&logo=c&logoColor=white)](https://en.wikipedia.org/wiki/C_(programming_language))
[![MPI](https://img.shields.io/badge/MPI-Message_Passing_Interface-blue.svg?style=for-the-badge)](https://www.mpi-forum.org/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge)](https://opensource.org/licenses/MIT)

---

## 📋 Overview
**MPI Parallel Matrix Multiplication** is a high-performance computing framework designed to execute massive matrix calculations efficiently. Built using the **Message Passing Interface (MPI)** in C, this project distributes computational workloads across multiple processors using advanced topological decompositions, drastically reducing execution time for large-scale matrices.

## 🎯 The Problem
Modern computational tasks require matrix operations that exceed the processing power and memory limits of single processors, leading to:
* **Computational Bottlenecks:** Single-core processors cannot scale efficiently to calculate $N \times N$ matrices when $N$ becomes extremely large.
* **Execution Delays:** Serial processing with $O(N^3)$ complexity creates unacceptable latency for scientific modeling.
* **Hardware Limitations:** Processing exceptionally large arrays sequentially exhausts centralized resources quickly.

## ✅ The Solution
This platform transforms serial bottlenecks into high-throughput parallel pipelines using a dual-topology mathematical strategy:

| Topology | Decomposition Strategy | MPI Features Utilized |
| :--- | :--- | :--- |
| **Ring Topology** | 1D Row-wise Decomposition | `MPI_Scatter`, `MPI_Bcast`, `MPI_Gather` |
| **Grid Topology** | 2D Cartesian Grid Decomposition | `MPI_Cart_create`, `MPI_Bcast` |

---

## 🏗️ Architecture & Workflow
The system follows a distributed memory architecture to separate data distribution from parallel computation:

1. **Ingestion Layer:** The Root process reads matrix data from `input.txt`.
2. **Topology Layer:** Virtual networks (1D Rings or 2D Grids) are formed via `MPI_Cart_create`.
3. **Distribution Layer:** Data is partitioned across compute nodes using `MPI_Scatter` and `MPI_Bcast`.
4. **Computation Layer:** Logical nodes perform localized dot-products on their specific sub-matrices (`APart`).
5. **Assembly Layer:** Sub-matrices are aggregated back to the Root process via `MPI_Gather` for the final output.

## 📂 Project Structure
```text
mpi-based-parallel-matrix-multiplication/
├── matrix_matrix_ring.c                  # ⭕ 1D Ring Topology Source
├── matrix_matrix_grid.c                  # 🔲 2D Grid Topology Source
├── input.txt                             # 📥 Initial Data (Matrix B and C)
├── outputA.txt                           # 📤 Computed Result Matrix
├── Setup and Code Execution Instructions.txt # ⚙️ Greek Instructions
├── Step And Commands.pdf                 # 📘 Setup Guide (PDF)
└── README.md                             # 📖 Project Documentation
```

🚀 Quick Start
### 1. Installation
```bash
git clone https://github.com/FilippeZ/mpi-based-parallel-matrix-multiplication.git
cd mpi-based-parallel-matrix-multiplication
# Set up WSL / Ubuntu environment first, then:
sudo apt-get update
sudo apt-get install libmpich-dev
```

### 2. Compilation
Compile for the topology of your choice (e.g., Ring Topology with $N=64$):
```bash
mpicc matrix_matrix_ring.c -o mmr -DN=64 -lm
```
*(For Grid Topology: `mpicc matrix_matrix_grid.c -o mmg -DN=64 -lm`)*

### 3. Launching the Cluster
Execute the compiled binary assigning the number of processors (e.g., `-np 11`):
```bash
mpirun -np 11 ./mmr < input.txt
```

---

## 🔬 Topology Deep Dive

### ⭕ 1D Ring Topology
Creates a logical, periodic one-dimensional ring using `MPI_Cart_create`.
* **Matrix B** is distributed row-by-row across processes. If $N$ is not completely divisible by the number of nodes, the Root process handles the remainder.
* **Matrix C** is broadcasted in its entirety to all nodes.
* Processed partitions are computationally separated and `MPI_Gather` reassembles the final matrix at the Root.

### 🔲 2D Grid Topology
Organizes computation nodes into a 2D checkerboard Cartesian grid coordinate system.
* Dimensions ($dim1 \times dim2$) are programmatically optimized to be as square-like as possible.
* Coordinate boundaries allow processes to identify exactly which matrix blocks they claim via `MPI_Cart_coords`.

## 🛠️ Tech Stack
* **Language:** C
* **Parallel API:** MPICH (Message Passing Interface)
* **OS Environment:** Linux & Windows Subsystem for Linux (WSL)
* **Math Library:** standard `<math.h>` (`-lm`)

## 📄 License
Licensed under the MIT License — see `LICENSE` for details.

## 👤 Author
**Filippos-Paraskevas Zygouris (FilippeZ)**
[Github] | https://github.com/FilippeZ
