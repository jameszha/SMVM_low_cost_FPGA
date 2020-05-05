# generate_matrix.py
#
# Generates random matrix, as well as its Compressed Sparse Row (CSR) and Compressed Interleaved
# Sparse Row (CISR) representations
#
# Author: James Zhang (jameszha@andrew.cmu.edu)
# Date: May. 2, 2020
#
import argparse
import os
import sys
import time

import numpy as np
from scipy import sparse

np.set_printoptions(linewidth=120)

# enable printing:
verbose=False

# Text color codes for fancy printouts
BLACK =     "\u001b[30m"
RED =       "\u001b[31m"
GREEN =     "\u001b[32m"
YELLOW =    "\u001b[33m"
BLUE =      "\u001b[34m"
MAGENTA =   "\u001b[35m"
CYAN =      "\u001b[36m"
WHITE =     "\u001b[37m"
RESET =     "\u001b[0m"

NUM_ROWS = 6

def generate_matrix(size=8, density=0.25, num_slots=4, output_name=None):
    # Generate random sparse square matrix with given size and density
    M = sparse.rand(NUM_ROWS, size, density=density, format="csr", dtype=np.uint8)
    if (verbose):
        print("Dense Format:")
        print("\t" + str(M.todense()).replace('\n','\n\t'))


    # Generate CSR representation
    csr_values = M.data
    csr_column_indices = M.indices
    csr_row_pointers = M.indptr
    if (verbose):
        print("\nCSR Format:")
        print("\tValues:         ", csr_values)
        print("\tColumn Indices: ", csr_column_indices)
        print("\tRow Pointers:   ", csr_row_pointers)


    # Generate CISR slot assignments
    num_nonzero = sparse.csr_matrix.count_nonzero(M)
    row_lengths = np.diff(M.indptr)
    slot_assignments = np.zeros(NUM_ROWS, dtype=int)
    slot_sizes = np.zeros(num_slots, dtype=int)
    for i in range(NUM_ROWS):
        next_slot = np.argmin(slot_sizes)
        slot_assignments[i] = next_slot
        slot_sizes[next_slot] += row_lengths[i]

    # Generate CISR representation
    cisr_row_lengths = np.zeros(num_slots * max(np.bincount(slot_assignments)), dtype=int) 
    cisr_values = np.zeros(num_slots * max(slot_sizes), dtype=int)
    cisr_column_indices = np.zeros(num_slots * max(slot_sizes), dtype=int) 
    for slot_id in range(num_slots): 
        slot_position = 0
        for row_id in range(NUM_ROWS):
            if (slot_assignments[row_id] == slot_id):
                for col_id in range(row_lengths[row_id]):
                    value = M.getrow(row_id).data[col_id]
                    column_id = M.getrow(row_id).indices[col_id]
                    cisr_values[slot_id + slot_position*num_slots] = value
                    cisr_column_indices[slot_id + slot_position*num_slots] = column_id
                    slot_position += 1
    for slot_id in range(num_slots):
        slot_position = 0;
        for row_id in range(NUM_ROWS):
            if (slot_assignments[row_id] == slot_id):
                cisr_row_lengths[slot_id + slot_position*num_slots] = row_lengths[row_id]
                slot_position += 1
    if (verbose):
        print("\nCISR Format:")
        print("\tRow-to-Slot assignments: ", slot_assignments)
        print("\tSlot sizes:              ", slot_sizes)
        print("\tCISR row lengths:        ", cisr_row_lengths)
        print("\tCISR values:             ", cisr_values)
        print("\tCISR column indices:     ", cisr_column_indices)


    if (output_name is not None):
        dense_file_path = output_name + ".csv"
        csr_file_path = output_name + "_csr.csv"
        cisr_file_path = output_name + "_cisr.csv"

        # Save dense matrix to <output_name>.csv
        np.savetxt(dense_file_path, M.todense(), delimiter = ",",  fmt='%d')

        # Save Compressed Sparse Row (CSR) format
        csr_header = 'Row 1: CSR Values\nRow 2: CSR Column Indices\nRow 3: CSR Row Pointers'
        with open(csr_file_path, 'a') as f:
            f.truncate(0)
            np.savetxt(f, csr_values.reshape(1, csr_values.shape[0]), delimiter=',',  fmt='%d', header=csr_header)
            np.savetxt(f, csr_column_indices.reshape(1, csr_column_indices.shape[0]), delimiter=',',  fmt='%d')
            np.savetxt(f, csr_row_pointers.reshape(1, csr_row_pointers.shape[0]), delimiter=',',  fmt='%d')

        # Save Compressed Interleaved Sparse Row (CISR) format
        cisr_header = 'Row 1: CISR Values\nRow 2: CISR Column Indices\nRow 3: CISR Row Lengths'
        with open(cisr_file_path, 'a') as f:
            f.truncate(0)
            np.savetxt(f, cisr_values.reshape(1, cisr_values.shape[0]), delimiter=',',  fmt='%d', header=cisr_header)
            np.savetxt(f, cisr_column_indices.reshape(1, cisr_column_indices.shape[0]), delimiter=',',  fmt='%d')
            np.savetxt(f, cisr_row_lengths.reshape(1, cisr_row_lengths.shape[0]), delimiter=',',  fmt='%d')
            
    return M

def get_args():

    def density_type(x):
        try:
            x = float(x)
        except ValueError:
            raise argparse.ArgumentTypeError("%r not a floating-point literal" % (x,))

        if (x < 0.0 or x > 1.0):
            raise argparse.ArgumentTypeError("%r not in range [0.0, 1.0]"%(x,))
        return x

    parser = argparse.ArgumentParser()

    parser.add_argument('-n', '--n', help="Matrix Size", type=int, default=8)
    parser.add_argument('-d', '--density', help="Matrix Density", type=density_type, default=0.25)
    parser.add_argument('-s', '--num_slots', help="Number of slots for CISR encoding.", type=int, default=4)
    parser.add_argument('-o', '--output', help="Output name. Produces files <output>.csv, <output>_csr.csv, <output>_cisr.csv")
    parser.add_argument('-v', '--verbose', help="Enables printouts of matrix representations", action='store_true')
    
    return parser.parse_args()


if __name__ == '__main__':
    start_time = time.time()

    args = get_args()

    if args.verbose:
        verbose = True

    generate_matrix(size=args.n, density=args.density, num_slots=args.num_slots, output_name=args.output)

    print("\nTotal time taken: " + str(time.time() - start_time) + " seconds")
    sys.stdout.flush()