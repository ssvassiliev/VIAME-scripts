#!/bin/bash
#SBATCH -c12 --mem-per-cpu=10000 --gpus-per-node=h100:1 --time=6:0:0

module load apptainer

# Training data location
export PROJECT_DIR=/project/def-kdavies/Project_VIAME_GSL2025_2026/2022-09-11
export OUTPUT_DIRECTORY=output

# Path to VIAME container
export VIAME_CONTAINER=/project/def-kdavies/viame.sif

# VIAME configuration location inside container
export VIAME_INSTALL=/opt/noaa/viame
export GPU_COUNT=1
export PIPES_PER_GPU=8

cd ${PROJECT_DIR}
# Run VIAME training inside container
apptainer exec --nv ${VIAME_CONTAINER} bash -c "
    source ${VIAME_INSTALL}/setup_viame.sh
    python ${VIAME_INSTALL}/configs/process_video.py \
        -l ${PROJECT_DIR}/input_list.txt \
        -p ${PROJECT_DIR}/pipelines/detector_project_folder.pipe \
	-o ${OUTPUT_DIRECTORY} \
	--no-reset-prompt \
        -gpus ${GPU_COUNT} \
	-pipes-per-gpu ${PIPES_PER_GPU}
"
