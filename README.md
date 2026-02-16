# MPI-Based Parallel Matrix Multiplication

This repository contains the source code and instructions for parallel matrix multiplication using MPI (Message Passing Interface). It includes implementations for both ring and grid topologies.

## Setup Instructions

### bash Terminal Setup (Windows)

1.  **Enable Windows Subsystem for Linux (WSL):**
    *   Go to Control Panel > Programs > Turn Windows features on or off.
    *   Enable "Windows Subsystem for Linux".
    *   Restart your computer.
    *   Install Ubuntu 16.04 (or a later version) from the Microsoft Store.

2.  **Terminal Configuration:**
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
