#!/bin/sh
CGP=/users/p16043/wilson/CGP.jl
DATA=/tmpdir/wilson/data/julia

EA=cgpneat
WORK_DIR=/tmpdir/wilson/dennis/$SLURM_JOB_ID/$SLURM_TASK_PID
CTYPES=(CGPChromo PCGPChromo HPCGPChromo FPCGPChromo EIPCGPChromo MTPCGPChromo)

mkdir -p $WORK_DIR
cd $CGP

for c in ${CTYPES[@]}
do
    julia experiments/atari.jl $SLURM_TASK_PID $WORK_DIR/$c.log $EA $c
done
