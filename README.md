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

## Technical Implementation

### Ring Topology (`matrix_matrix_ring.c`)
This implementation utilizes a **1D Row-wise Decomposition** strategy.

*   **Topology**: A 1D logical ring topology is created using `MPI_Cart_create` (1D, periodic).
*   **Data Distribution**:
    *   **Matrix B**: Distributed (scattered) among processes using `MPI_Scatter`. The root process handles extra rows if $N$ is not divisible by the number of processes.
    *   **Matrix C**: Replicated (broadcast) to all processes using `MPI_Bcast`. Every process receives the full Matrix C.
*   **Computation**: Each process computes a sub-block of the result matrix $A$ (`APart`) corresponding to the rows of $B$ it received. The partial results are then gathered back to the root process using `MPI_Gather`.

### Grid Topology (`matrix_matrix_grid.c`)
This implementation utilizes a **2D Grid Decomposition** strategy.

*   **Topology**: A 2D Cartesian grid topology is created using `MPI_Cart_create`. The dimensions ($dim1 \times dim2$) are calculated to be as square as possible for the given number of processes.
*   **Data Distribution**:
    *   **Matrices B and C**: In this specific implementation, **both full matrices B and C are broadcast** to all processes using `MPI_Bcast`. Each process then extracts the specific sub-blocks it needs for calculation based on its grid coordinates. *Note: While simpler, this approach is less memory efficient than distributing only the necessary sub-blocks.*
*   **Computation**: Each process calculates a specific sub-block of matrix $A$ (`APart`) defined by its coordinates in the grid. The root process then collects these sub-blocks from all other processes to reconstruct the final matrix $A$.

## Key MPI Functions

*   `MPI_Init` / `MPI_Finalize`: Initialize and terminate the MPI environment.
*   `MPI_Comm_rank` / `MPI_Comm_size`: Determine process ID and total number of processes.
*   `MPI_Cart_create`: Creates a new communicator with a Cartesian topology.
*   `MPI_Cart_coords`: Determines process coordinates in the Cartesian topology.
*   `MPI_Cart_shift`: (Ring) Finds neighbors for shifting data in the ring.
*   `MPI_Scatter`: Distributes data from one process to all others in a communicator.
*   `MPI_Bcast`: Broadcasts a message from the process with rank `root` to all other processes of the communicator.
*   `MPI_Gather`: Gathers values from a group of processes together to one process.

## Setup Instructions

### bash Terminal Setup (Windows)

1.  **Enable Windows Subsystem for Linux (WSL)**:
    *   Go to Control Panel > Programs > Turn Windows features on or off.
    *   Enable "Windows Subsystem for Linux".
    *   Restart your computer.
    *   Install Ubuntu 16.04 (or a later version) from the Microsoft Store.

2.  **Terminal Configuration**:
    *   Open the Ubuntu terminal.
    *   Run the following commands to update and install necessary libraries:
        ```bash
        sudo apt-get update
        sudo apt-get install libmpich-dev
        ```

## Compilation

The code is compiled using the `mpicc` wrapper compiler.

### Ring Topology
To compile the code for the ring topology:

```bash
mpicc matrix_matrix_ring.c -o mmr -DN=64 -lm
```
*   `mpicc`: The MPI C compiler wrapper.
*   `matrix_matrix_ring.c`: Source file for ring topology.
*   `-o mmr`: Output executable name.
*   `-DN=64`: Defines the matrix size $N=64$.
*   `-lm`: Links the math library.

### Grid Topology
To compile the code for the grid topology:

```bash
mpicc matrix_matrix_grid.c -o mmg -DN=64 -lm
```
*   `mpicc`: The MPI C compiler wrapper.
*   `matrix_matrix_grid.c`: Source file for grid topology.
*   `-o mmg`: Output executable name.
*   `-DN=64`: Defines the matrix size $N=64$.
*   `-lm`: Links the math library.

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

### Ring Topology
To run the ring topology implementation:

```bash
mpirun -np 11 ./mmr < input.txt
```
*   `mpirun`: Command to run MPI programs.
*   `-np 11`: Specifies the number of processes (11 in this example).
*   `./mmr`: The executable file.
*   `< input.txt`: Redirects standard input from `input.txt` (contains matrix data).

### Grid Topology
To run the grid topology implementation:

```bash
mpirun -np 11 ./mmg < input.txt
```
*   `mpirun`: Command to run MPI programs.
*   `-np 11`: Specifies the number of processes.
*   `./mmg`: The executable file.
*   `< input.txt`: Input data file.

### Output
Upon successful execution:
1.  The console will display the time taken: `Total time taken: X secs`.
2.  A file named **`outputA.txt`** will be generated containing the calculated result matrix.
