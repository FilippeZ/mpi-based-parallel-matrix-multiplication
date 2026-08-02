# Makefile for MPI Parallel Matrix Multiplication

MPICC   ?= mpicc
CFLAGS  ?= -O2 -Wall
MATHLIB ?= -lm
N       ?= 64
NP      ?= 11

BIN_DIR := bin
SRC_DIR := src
DATA_DIR := data

RING_SRC := $(SRC_DIR)/matrix_matrix_ring.c
GRID_SRC := $(SRC_DIR)/matrix_matrix_grid.c

RING_BIN := $(BIN_DIR)/mmr
GRID_BIN := $(BIN_DIR)/mmg

.PHONY: all ring grid clean run-ring run-grid help

all: ring grid

ring: $(RING_SRC) | $(BIN_DIR)
	$(MPICC) $(CFLAGS) $(RING_SRC) -o $(RING_BIN) -DN=$(N) $(MATHLIB)

grid: $(GRID_SRC) | $(BIN_DIR)
	$(MPICC) $(CFLAGS) $(GRID_SRC) -o $(GRID_BIN) -DN=$(N) $(MATHLIB)

$(BIN_DIR):
	mkdir -p $(BIN_DIR)

run-ring: ring
	mpirun -np $(NP) ./$(RING_BIN) < $(DATA_DIR)/input.txt

run-grid: grid
	mpirun -np $(NP) ./$(GRID_BIN) < $(DATA_DIR)/input.txt

clean:
	rm -rf $(BIN_DIR)/*

help:
	@echo "MPI Parallel Matrix Multiplication Build Options:"
	@echo "  make all          - Build both Ring and Grid executables"
	@echo "  make ring N=64    - Compile 1D Ring topology (default N=64)"
	@echo "  make grid N=64    - Compile 2D Grid topology (default N=64)"
	@echo "  make run-ring NP=11 - Execute Ring binary with NP processes"
	@echo "  make run-grid NP=11 - Execute Grid binary with NP processes"
	@echo "  make clean        - Remove compiled binaries"
