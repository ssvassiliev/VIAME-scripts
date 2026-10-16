#!/bin/bash
#SBATCH -c12 --mem-per-cpu=10000 --gpus-per-node=h100:1 --time=20:0:0

module load apptainer

# Training data location
export PROJECT_DIR=/project/6112925/Project_Loutet_Shadowgraph/training-data-20260921

# Path to VIAME container
export VIAME_CONTAINER=/project/6112925/Project_Loutet_Shadowgraph/viame.sif
# VIAME configuration location inside container
export VIAME_INSTALL=/opt/noaa/viame

# Run VIAME training inside container
apptainer exec --nv "${VIAME_CONTAINER}" bash -c "
    source ${VIAME_INSTALL}/setup_viame.sh
    viame train \
        -i ${PROJECT_DIR} \
        -c ${VIAME_INSTALL}/configs/pipelines/train_detector_default.conf \
        --threshold 0.0
"
