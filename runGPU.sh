#!/bin/bash

# set env variables
export OMP_NUM_THREADS=1 # there are 56x2x2 = 224 threads available in the CPU
export OMP_TARGET_OFFLOAD=MANDATORY # controls the program behavior when offloading a target region
# export LIBOMPTARGET_DEBUG=1 # controls whether debugging information will be displayed from the offload runtime
# export LIBOMPTARGET_PLUGIN_PROFILE=T,usec # enables basic plugin profiling and displays the result when program finishes. can be used to get HtD and DtH timings

# set variables
RUN_CLASS=A # should be in A-E
VTUNE_OR_ADV_RUN=0 # should be 0 or in 3-8
USE_TIMER=0 # should be 0 or 1

# set constants
GPU_RUN_DIR="NPB-OMP-GPU"
RUN_PATH="/home/$USER/Multicore_Processors_and_Embedded_Systems/NAS-OMP_Project/$GPU_RUN_DIR"
EXE_PATH="./bin/lu.$RUN_CLASS"
TIMER_FLAG_FILE=timer.flag

VTUNE_CPU_HOTSPOTS_DIR="./vtune_hotspots"
ADV_VEC_DIR="./adv_vectorization"
ADV_OFFLOAD_DIR="./adv_offload_model"
VTUNE_GPU_OFFLOAD_DIR="./vtune_gpu_offload_unopt"
VTUNE_GPU_HOTSPOTS_DIR="./vtune_gpu_hotspots_unopt"
ADV_GPU_ROOFLINE_DIR="./adv_gpu_roofline_opt"

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
elif [ $VTUNE_OR_ADV_RUN -eq 6 ]; then
    rm -r $VTUNE_GPU_OFFLOAD_DIR
    vtune -collect gpu-offload  --result-dir=${VTUNE_GPU_OFFLOAD_DIR} -- ${EXE_PATH}
elif [ $VTUNE_OR_ADV_RUN -eq 7 ]; then
    rm -r $VTUNE_GPU_HOTSPOTS_DIR
    vtune -collect gpu-hotspots --result-dir=${VTUNE_GPU_HOTSPOTS_DIR} -- ${EXE_PATH}
elif [ $VTUNE_OR_ADV_RUN -eq 8 ]; then
    rm -r $ADV_GPU_ROOFLINE_DIR
    advisor --collect=roofline --profile-gpu --search-dir src:r=src --project-dir=${ADV_GPU_ROOFLINE_DIR} -- ${EXE_PATH}
fi