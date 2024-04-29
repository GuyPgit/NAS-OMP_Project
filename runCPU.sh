#!/bin/bash

# set env variables
export OMP_NUM_THREADS=224 # there are 56x2x2 = 224 threads available in the CPU

# set variables
RUN_CLASS=B # should be in A-C
VTUNE_OR_ADV_RUN=0 # should be 0 or in 3-5
USE_TIMER=0 # should be 0 or 1

# set constants
CPU_RUN_DIR="NPB-OMP"
RUN_PATH="/home/$USER/Multicore_Processors_and_Embedded_Systems/NAS-OMP_Project/$CPU_RUN_DIR"
EXE_PATH="./bin/lu.$RUN_CLASS"
TIMER_FLAG_FILE=timer.flag

VTUNE_CPU_HOTSPOTS_DIR="./vtune_hotspots"
ADV_VEC_DIR="./adv_vectorization"
ADV_OFFLOAD_DIR="./adv_offload_model"

# navigate to path from which we compile the code
cd $RUN_PATH

# set timer flag file
if [ $USE_TIMER -eq 0 ]; then
    if [ -f "$TIMER_FLAG_FILE" ]; then
        mv "$TIMER_FLAG_FILE" "$TIMER_FLAG_FILE.off"
    fi
else
    if [ -f "$TIMER_FLAG_FILE.off" ]; then
        mv "$TIMER_FLAG_FILE.off" "$TIMER_FLAG_FILE"
    fi
fi

# compile code
make lu CLASS=$RUN_CLASS

# execute code
if [ $VTUNE_OR_ADV_RUN -eq 0 ]; then
    ./bin/lu.${RUN_CLASS}
fi

# analysis with vtune and advisor
if [ $VTUNE_OR_ADV_RUN -eq 3 ]; then
    rm -r $VTUNE_CPU_HOTSPOTS_DIR
    vtune -collect hotspots -knob sampling-mode=hw --result-dir=${VTUNE_CPU_HOTSPOTS_DIR} -- ${EXE_PATH}
elif [ $VTUNE_OR_ADV_RUN -eq 4 ]; then
    rm -r $ADV_VEC_DIR
    advisor --collect=survey --project-dir=${ADV_VEC_DIR} -- ${EXE_PATH}
elif [ $VTUNE_OR_ADV_RUN -eq 5 ]; then
    rm -r $ADV_OFFLOAD_DIR
    advisor --collect=offload --config=gen12_tgl --project-dir=${ADV_OFFLOAD_DIR} -- ${EXE_PATH}
fi