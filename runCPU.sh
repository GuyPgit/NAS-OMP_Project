#!/bin/bash

# set variables
RUN_CLASS=A
RUN_PATH="/home/$USER/Multicore_Processors_and_Embedded_Systems/NAS-OMP_Project/NPB-OMP"
EXE_PATH="./bin/lu.$RUN_CLASS"
VTUNE_CPU_HOTSPOTS_PATH="./vtune_hotspots"
ADV_VEC_PATH="./adv_vectorization"

# navigate to path from which we compile the code
cd $RUN_PATH

# clean analysis data folders
rm -rf VTUNE_CPU_HOTSPOTS_PATH ADV_VEC_PATH

# set env variables
export OMP_NUM_THREADS=1 # there are 56x2x2 = 224 threads available in the CPU

# compile code
make lu CLASS=$RUN_CLASS

# execute code
./bin/lu.${RUN_CLASS}

# analysis with vtune and more
# vtune -collect hotspots -knob sampling-mode=hw --result-dir=${VTUNE_CPU_HOTSPOTS_PATH} -- ${EXE_PATH}
# advisor --collect=survey --project-dir=${ADV_VEC_PATH} -- ${EXE_PATH}