#!/bin/bash
#SBATCH --cpus-per-task=2
#SBATCH --mem-per-cpu=4000 
#SBATCH --gpus=h100_1g.10gb:1
#SBATCH --time=1:0:0

# Project and training location

PROJECT_DIR=/project/6112925/Project_Loutet_Shadowgraph
export TRAINING_DIR=${PROJECT_DIR}/Training-20260921

export IMAGE_LIST=${TRAINING_DIR}/inference_images_100.txt

# Path to VIAME container
export VIAME_CONTAINER=${PROJECT_DIR}/viame.sif

# VIAME configuration location inside container
export VIAME_INSTALL=/opt/noaa/viame
export GPU_COUNT=1
export PIPES_PER_GPU=8

cd ${TRAINING_DIR}


# Run VIAME training inside container
mkdir -p ${TRAINING_DIR}/test_output

module load apptainer
apptainer exec --nv ${VIAME_CONTAINER} bash -c "
    source ${VIAME_INSTALL}/setup_viame.sh
    python ${VIAME_INSTALL}/configs/process_video.py \
        -l ${IMAGE_LIST} \
        -p ${TRAINING_DIR}/category_models/run.pipe \
        -o ${TRAINING_DIR}/test_output \
        --no-reset-prompt \
        -gpus ${GPU_COUNT} \
        -pipes-per-gpu ${PIPES_PER_GPU}
"
