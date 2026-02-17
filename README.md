# MPI-Based Parallel Matrix Multiplication

## Project Description
This project implements **Matrix-Matrix Multiplication** using the **Message Passing Interface (MPI)** to parallelize computations across multiple processors. High-performance computing tasks often require calculations too massive for a single computer to handle efficiently. This project solves that problem by splitting the workload among a "team" of processors.

The application is written in C and demonstrates two distinct logical topologies for organizing processes:
1.  **Ring Topology**: Processes are arranged in a logical ring where data flows in a circle. Utilizes a **1D Row-wise Decomposition** strategy.
2.  **Grid Topology**: Processes are arranged in a 2D checkerboard (Cartesian grid). Utilizes a **2D Grid Decomposition** strategy.

## Key Features
*   **Parallel Computation**: Utilizes `MPI_Scatter`, `MPI_Gather`, and `MPI_Bcast` to distribute data and collect results, significantly reducing execution time compared to serial processing.
*   **Flexible Topologies**:
    *   **Ring**: Implements a 1D decomposition where the Root process scatters rows of Matrix B and broadcasts Matrix C.
    *   **Grid**: Implements a 2D decomposition using `MPI_Cart_create` to organize processes into coordinates.
*   **Dynamic Matrix Sizing**: The matrix dimension ($N \times N$) can be defined at compile-time using preprocessor macros (e.g., `-DN=64`).
*   **File I/O Integration**: Reads input matrices from a file (`input.txt`) and writes the assembled result to an output file (`outputA.txt`).
*   **Performance Metrics**: The application measures and reports the total execution time using `MPI_Wtime`.

## Setup Instructions

### bash Terminal Setup (Windows WSL & Linux)
To build and run this project, you need a Linux environment with the GCC compiler and MPICH library installed.

1.  **Enable Windows Subsystem for Linux (WSL)** (Windows Users):
    *   Go to Control Panel > Programs > Turn Windows features on or off.
    *   Enable "Windows Subsystem for Linux".
    *   Restart your computer.
    *   Install Ubuntu from the Microsoft Store.

2.  **Install Dependencies**:
    Open your terminal (Ubuntu/WSL) and run:
    ```bash
    sudo apt-get update
    sudo apt-get install libmpich-dev
    ```

## Compilation

The project includes two source files: `matrix_matrix_ring.c` and `matrix_matrix_grid.c`. You must compile them using the MPI wrapper compiler, `mpicc`.

### Ring Topology
To compile the code for the ring topology:
```bash
mpicc matrix_matrix_ring.c -o mmr -DN=64 -lm
```
*   `mpicc`: The MPI C compiler wrapper.
*   `-o mmr`: Sets the output executable name to `mmr`.
*   `-DN=64`: Defines the matrix size $N=64$.
*   `-lm`: Links the math library.

### Grid Topology
To compile the code for the grid topology:
```bash
mpicc matrix_matrix_grid.c -o mmg -DN=64 -lm
```
*   `-o mmg`: Sets the output executable name to `mmg`.

## Execution

The compiled programs are executed using `mpirun`.

### Input File Format (`input.txt`)
The input file should contain the integer values for **Matrix B** followed by **Matrix C**. The Root process reads this file.
*Example format:*
```text
0 1 0
0 0 1
1 0 0
...
```

### Running the Code
Use `mpirun` to execute the compiled programs. You must specify the number of processes (`-np`) and redirect the input file.

**Ring Topology:**
```bash
mpirun -np 11 ./mmr < input.txt
```

**Grid Topology:**
```bash
mpirun -np 11 ./mmg < input.txt
```

*   `-np 11`: Spawns 11 processes. You may adjust this number.
*   `< input.txt`: Redirects standard input from `input.txt` (contains matrix data).

### Output
Upon successful execution:
1.  The console will display the time taken: `Total time taken: X secs`.
2.  A file named **`outputA.txt`** will be generated containing the calculated result matrix.

## Implementation Details

### Ring Topology Strategy (`matrix_matrix_ring.c`)
1.  **Initialization**: `MPI_Init` sets up the environment. `MPI_Cart_create` arranges processes in a 1D ring (periodic).
2.  **Data Distribution**:
    *   **Matrix B**: Distributed (scattered) among processes using `MPI_Scatter`.
    *   **Matrix C**: Replicated (broadcast) to all processes using `MPI_Bcast`.
3.  **Computation**: Each process computes a sub-block of the result matrix $A$ corresponding to the rows of $B$ it received.
4.  **Gather**: The Root process collects all partial parts using `MPI_Gather` to reconstruct the final Matrix A.

### Grid Topology Strategy (`matrix_matrix_grid.c`)
1.  **Setup**: Uses `MPI_Cart_create` to create a 2D Cartesian grid topology. Dimensions ($dim1 \times dim2$) are calculated to be as square as possible.
2.  **Data Distribution**:
    *   In this implementation, **both full matrices B and C are broadcast** (`MPI_Bcast`) to all processes. Each process extracts the specific sub-blocks it needs.
3.  **Computation**: Each process calculates a specific sub-block of matrix $A$ defined by its coordinates in the grid.
4.  **Gather**: The Root process collects these sub-blocks from all other processes to reconstruct the final matrix $A$.

### Memory Management
The application utilizes dynamic memory allocation for 2D matrices (`malloc`) and ensures all allocated memory for matrices A, B, and C is freed using `free` before `MPI_Finalize` to prevent memory leaks.
