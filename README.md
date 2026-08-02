# 🧮 High-Performance MPI Parallel Matrix Multiplication

A robust, distributed-memory parallel matrix multiplication framework implemented in **C** using the **Message Passing Interface (MPI)**. This project explores high-performance computing (HPC) paradigms through two distinct virtual process communication topologies: **1D Periodic Ring Topology** and **2D Cartesian Grid Topology**.

---

[![Language: C](https://img.shields.io/badge/Language-C-00599C.svg?style=for-the-badge&logo=c&logoColor=white)](https://en.wikipedia.org/wiki/C_(programming_language))
[![MPI: MPICH](https://img.shields.io/badge/MPI-MPICH%2FOpenMPI-003366.svg?style=for-the-badge)](https://www.mpi-forum.org/)
[![Platform: Linux / WSL](https://img.shields.io/badge/Platform-Linux%20%7C%20WSL-FCC624.svg?style=for-the-badge&logo=linux&logoColor=black)](https://ubuntu.com/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge)](https://opensource.org/licenses/MIT)

---

## 📌 Table of Contents

- [Overview & Architecture](#-overview--architecture)
- [Mathematical Foundations](#-mathematical-foundations)
- [Topology Implementations](#-topology-implementations)
  - [1D Periodic Ring Topology](#1-1d-periodic-ring-topology-srcmatrix_matrix_ringc)
  - [2D Cartesian Grid Topology](#2-2d-cartesian-grid-topology-srcmatrix_matrix_gridc)
- [MPI Communication Primitives](#-mpi-communication-primitives)
- [Performance & Computational Complexity](#-performance--computational-complexity)
- [Directory Structure](#-directory-structure)
- [Prerequisites & Environment Setup](#-prerequisites--environment-setup)
- [Compilation & Execution](#-compilation--execution)
- [Input / Output File Format](#-input--output-file-format)
- [Demonstration & Media](#-demonstration--media)
- [License & Author](#-license--author)

---

## 📋 Overview & Architecture

Dense matrix multiplication ($A = B \times C$) is a foundational workload in scientific computing, machine learning, and linear algebra routines (BLAS level 3). As matrix dimensions $N \times N$ scale into tens of thousands of elements, serial CPU computation encounters severe CPU instruction latency and main memory memory-bandwidth limitations.

This project delivers a distributed parallel implementation leveraging **MPICH** to split computational workloads across $P$ logical processing ranks. By organizing processes into virtual network topologies via MPI Cartesian mapping functions, memory footprint is partitioned and computation is parallelized across multiple cores or cluster nodes.

```
                  +-----------------------------------+
                  |        Root Process (Rank 0)      |
                  |  Reads Input Data: Matrix B & C   |
                  +-----------------+-----------------+
                                    |
          +-------------------------+-------------------------+
          |                                                   |
          v                                                   v
+-----------------------------+           +-----------------------------+
|    1D Ring Topology         |           |    2D Grid Topology          |
|  - 1D Row Partitioning      |           |  - 2D Block Partitioning    |
|  - MPI_Cart_create (dim=1)  |           |  - MPI_Cart_create (dim=2)  |
|  - Ring Shifts / Broadcast  |           |  - Sub-grid Coordinates     |
+--------------+--------------+           +--------------+--------------+
               |                                         |
               +--------------------+--------------------+
                                    |
                                    v
                  +-----------------------------------+
                  |         Parallel Computation      |
                  | A_part[i][j] = sum(B_part * C)    |
                  +-----------------+-----------------+
                                    |
                                    v
                  +-----------------------------------+
                  |   MPI_Gather / Aggregation        |
                  | Root collects results to outputA   |
                  +-----------------------------------+
```

---

## 🧮 Mathematical Foundations

Given two dense square matrices $B \in \mathbb{R}^{N \times N}$ and $C \in \mathbb{R}^{N \times N}$, the product matrix $A \in \mathbb{R}^{N \times N}$ is defined element-wise as:

$$A_{i,j} = \sum_{k=0}^{N-1} B_{i,k} \cdot C_{k,j}, \quad \text{for } 0 \le i, j < N$$

### Sequential Complexity
- **Time Complexity:** $\mathcal{O}(N^3)$ multiplications and additions.
- **Space Complexity:** $\mathcal{O}(N^2)$ memory locations for input and output storage.

### Parallel Decomposition
In a distributed environment with $P$ processing nodes:
1. **Matrix $B$ Partitioning:** Row blocks of size $\frac{N}{P} \times N$ (for 1D Ring) or 2D sub-blocks of size $\frac{N}{\text{dim}_1} \times \frac{N}{\text{dim}_2}$ (for 2D Grid) are distributed across ranks.
2. **Matrix $C$ Distribution:** Either broadcasted in its entirety or distributed in sub-blocks to participating processes.
3. **Local Computation:** Each rank computes its assigned sub-matrix elements $A_{\text{part}}$ independently.

---

## 📐 Topology Implementations

### 1. 1D Periodic Ring Topology (`src/matrix_matrix_ring.c`)

The 1D Ring Topology arranges $P$ processes in a closed, periodic one-dimensional ring network.

```text
[Rank 0] <---> [Rank 1] <---> [Rank 2] <---> ... <---> [Rank P-1] <---> [Rank 0]
```

- **Topological Setup:** Initialized via `MPI_Cart_create` with a 1D dimension array `dim[1] = {num_procs}` and periodicity enabled (`period[1] = {1}`).
- **Data Decomposition:** Matrix $B$ is partitioned row-wise. Each rank receives $r = \lfloor N / P \rfloor$ rows.
- **Dynamic Remainder Handling:** When matrix dimension $N$ is not cleanly divisible by process count $P$ ($N \pmod P \neq 0$), the root process ($P_0$) absorbs the extra rows $r_{\text{extra}} = N \pmod P$, taking responsibility for $r + r_{\text{extra}}$ rows.
- **Communication Workflow:**
  1. **Root Process ($P_0$):** Reads input matrices $B$ and $C$ from file or stdin.
  2. **Row Distribution:** Scatter/send row subsets of $B$ to corresponding ranks.
  3. **Broadcasting Matrix $C$:** Root process broadcasts complete matrix $C$ to all ranks using `MPI_Bcast`.
  4. **Parallel Computation:** Ranks calculate partial row-wise inner products:
     $$\text{APart}_{i,j} = \sum_{k=0}^{N-1} \text{BPart}_{i,k} \cdot C_{k,j}$$
  5. **Data Collection:** Results are gathered back to Root using `MPI_Gather` (or custom send/receive for variable rank sizes).

### 2. 2D Cartesian Grid Topology (`src/matrix_matrix_grid.c`)

The 2D Grid Topology organizes processes into a 2-dimensional grid coordinate system $(\text{dim}_1 \times \text{dim}_2 = P)$.

```text
+---------------+---------------+---------------+
| Rank (0,0)    | Rank (0,1)    | Rank (0,2)    |
+---------------+---------------+---------------+
| Rank (1,0)    | Rank (1,1)    | Rank (1,2)    |
+---------------+---------------+---------------+
| Rank (2,0)    | Rank (2,1)    | Rank (2,2)    |
+---------------+---------------+---------------+
```

- **Factorization Algorithm (`findMultiples`):** Dynamically computes grid dimensions $(\text{dim}_1, \text{dim}_2)$ such that $\text{dim}_1 \times \text{dim}_2 = P$ while minimizing the aspect ratio difference $|\text{dim}_1 - \text{dim}_2|$ to create as close to a square process grid as possible.
- **Cartesian Coordinate Mapping:**
  - Topology creation: `MPI_Cart_create(..., 2, dims, periods, reorder, &grid_comm)`.
  - Rank translation: `MPI_Cart_coords` and `MPI_Cart_rank` map process ranks to grid coordinates $(r, c)$.
- **Sub-Block Partitioning:** Matrices $B$ and $C$ are split into sub-blocks. Each process rank operates on a sub-block of size $(\text{rows\_per\_proc} \times \text{cols\_per\_proc})$.
- **Inter-Process Communication:** Uses sub-communicators and rank shifts (`MPI_Cart_shift`) across grid rows and columns for synchronized block exchanges.

---

## 🛠️ MPI Communication Primitives

| MPI Primitive | Usage & Functionality | Topology Context |
| :--- | :--- | :--- |
| `MPI_Init` | Initializes the MPI execution environment across all ranks. | Global Setup |
| `MPI_Comm_rank` | Retrieves process ID (rank) within `MPI_COMM_WORLD`. | Global Setup |
| `MPI_Comm_size` | Obtains total number of processes $P$. | Global Setup |
| `MPI_Cart_create` | Creates virtual 1D Ring or 2D Grid communicator topology. | Topology Setup |
| `MPI_Cart_coords` | Translates rank ID into grid coordinate tuple $(r, c)$. | 2D Grid |
| `MPI_Cart_rank` | Translates grid coordinates back into a rank ID. | 2D Grid |
| `MPI_Cart_shift` | Finds neighbor ranks (`source`, `dest`) along grid dimensions. | 1D Ring / 2D Grid |
| `MPI_Bcast` | Broadcasts matrix $C$ or sub-blocks from Root to all processes. | Data Distribution |
| `MPI_Scatter` / `MPI_Send` | Distributes rows or blocks of Matrix $B$ across ranks. | Data Distribution |
| `MPI_Gather` / `MPI_Recv` | Collects computed sub-matrices $\text{APart}$ back to Root. | Result Collection |
| `MPI_Wtime` | High-resolution wall-clock timer for performance benchmarking. | Benchmarking |
| `MPI_Finalize` | Terminates MPI execution and releases resources. | Global Teardown |

---

## 📊 Performance & Computational Complexity

### Theoretical Speedup & Efficiency

Let $N$ be matrix dimension and $P$ be total MPI ranks:

| Metric | Serial Algorithm | 1D Ring Topology | 2D Grid Topology |
| :--- | :--- | :--- | :--- |
| **Computation Complexity** | $\mathcal{O}(N^3)$ | $\mathcal{O}\left(\frac{N^3}{P}\right)$ | $\mathcal{O}\left(\frac{N^3}{P}\right)$ |
| **Memory per Process** | $\mathcal{O}(N^2)$ | $\mathcal{O}\left(\frac{N^2}{P} + N^2\right)$ | $\mathcal{O}\left(\frac{N^2}{\sqrt{P}}\right)$ |
| **Communication Volume** | $0$ | $\mathcal{O}(N^2 \cdot P)$ (Full $C$ broadcast) | $\mathcal{O}\left(\frac{N^2}{\sqrt{P}}\right)$ (Sub-block shift) |
| **Scalability Limit** | $P=1$ | Scalable up to $P \le N$ | Scalable up to $P \le N^2$ |

### Scalability Insights
- **1D Ring** is simple and highly effective for small to medium process counts ($P \le 16$). However, broadcasting the full matrix $C$ to every process creates a memory and bandwidth bottleneck for huge $N$.
- **2D Grid** achieves optimal memory scalability $\mathcal{O}(N^2 / \sqrt{P})$ per process node, making it the preferred architectural choice for massively parallel supercomputing environments ($P \gg 64$).

---

## 📁 Directory Structure

```text
mpi-based-parallel-matrix-multiplication/
├── src/                                  # C Source Code Files
│   ├── matrix_matrix_ring.c              # 1D Ring Topology implementation
│   └── matrix_matrix_grid.c              # 2D Grid Topology implementation
├── data/                                 # Input Data & Output Results
│   ├── input.txt                         # Sample matrices B and C input data
│   └── outputA.txt                       # Computed result matrix output
├── docs/                                 # Documentation & Step-by-Step Guides
│   ├── Setup and Code Execution Instructions.txt # Ubuntu/WSL guide (Greek)
│   └── Step And Commands.pdf             # Execution flowchart & guide PDF
├── media/                                # Video Demonstrations & Screencasts
│   ├── Matrix-Matrix-Multiplication.mp4  # Run demonstration video 1
│   ├── Multiplication.mp4                # Run demonstration video 2
│   └── Parallel Matrix Multiplication.mp4# Run demonstration video 3
├── bin/                                  # Output directory for compiled binaries
├── Makefile                              # Automated build & execution Makefile
├── .gitignore                            # Git ignore rule specifications
└── README.md                             # Comprehensive project documentation
```

---

## 💻 Prerequisites & Environment Setup

### System Requirements
- Operating System: **Linux (Ubuntu 18.04/20.04/22.04)** or **Windows Subsystem for Linux (WSL / WSL2)**.
- Compiler: `gcc` / `mpicc` (MPICH or OpenMPI wrapper compiler).
- Build Tools: `make`.

### Installing MPICH on Ubuntu / WSL

```bash
# Update package manager lists
sudo apt-get update

# Install MPICH developer libraries and compiler tools
sudo apt-get install -y build-essential libmpich-dev mpich
```

---

## 🚀 Compilation & Execution

A feature-rich [`Makefile`](Makefile) is provided to streamline build and execution workflows.

### Quick Build with Makefile

```bash
# Build both Ring (mmr) and Grid (mmg) binaries with default matrix size N=64
make all

# Build specifically for 1D Ring Topology with N=128
make ring N=128

# Build specifically for 2D Grid Topology with N=128
make grid N=128
```

### Manual Compilation with `mpicc`

```bash
# Create binary directory
mkdir -p bin

# Compile Ring Topology (e.g. N=64)
mpicc -O2 -Wall src/matrix_matrix_ring.c -o bin/mmr -DN=64 -lm

# Compile Grid Topology (e.g. N=64)
mpicc -O2 -Wall src/matrix_matrix_grid.c -o bin/mmg -DN=64 -lm
```

---

### Executing the Cluster

Execute the compiled parallel program specifying the desired process count ($P$) via `mpirun` / `mpiexec`:

#### Using Makefile Targets:
```bash
# Run 1D Ring Topology with 11 MPI ranks
make run-ring NP=11

# Run 2D Grid Topology with 11 MPI ranks
make run-grid NP=11
```

#### Direct Execution Commands:
```bash
# Run 1D Ring Topology executable with 11 ranks using input data redirection
mpirun -np 11 ./bin/mmr < data/input.txt

# Run 2D Grid Topology executable with 11 ranks using input data redirection
mpirun -np 11 ./bin/mmg < data/input.txt
```

---

## 📥 Input / Output File Format

### Input Format (`data/input.txt`)
The input text file contains whitespace-separated integers representing the matrix elements of Matrix $B$ ($N \times N$) followed by Matrix $C$ ($N \times N$):

```text
# Matrix B (e.g., 4x4)
1  2  3  4
5  6  7  8
9 10 11 12
13 14 15 16

# Matrix C (e.g., 4x4)
1  0  0  0
0  1  0  0
0  0  1  0
0  0  0  1
```

### Output Format (`data/outputA.txt`)
Upon successful computation, Root (Rank 0) formats and writes the product Matrix $A$ to `data/outputA.txt` (or stdout):

```text
Computed Result Matrix A (N x N):
1  2  3  4
5  6  7  8
9 10 11 12
13 14 15 16
```

---

## 🎥 Demonstration & Media

Visual demonstrations showing setup, compilation, and parallel execution logs are stored in the [`media/`](media/) folder:

- 🎬 **`media/Matrix-Matrix-Multiplication.mp4`**: Execution walkthrough under 1D Ring topology.
- 🎬 **`media/Multiplication.mp4`**: Parallel matrix multiplication terminal run.
- 🎬 **`media/Parallel Matrix Multiplication.mp4`**: Full setup and execution demonstration.

---

## 📄 License & Author

### License
This project is open-source software licensed under the [MIT License](https://opensource.org/licenses/MIT).

### Author
**Filippos-Paraskevas Zygouris (FilippeZ)**

- 🐙 **GitHub:** [@FilippeZ](https://github.com/FilippeZ)
