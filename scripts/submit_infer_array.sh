#!/bin/bash
#SBATCH --cpus-per-task=2
#SBATCH --mem-per-cpu=4000 
#SBATCH --gpus=h100_3g.40gb:1
#SBATCH --time=1:0:0
#SBATCH --array=0-39

# ============================================================
# User-adjustable parameters
# ============================================================

# Project and training location
PROJECT_DIR=/project/6112925/Project_Loutet_Shadowgraph
export TRAINING_DIR=${PROJECT_DIR}/Training-20260921
# List of images for inference
export IMAGE_LIST=${TRAINING_DIR}/inference_images.txt
# Path to the VIAME container
export VIAME_CONTAINER=${PROJECT_DIR}/viame.sif

# ============================================================
# Internal configuration — do not modify below this line
# ============================================================

export VIAME_INSTALL=/opt/noaa/viame
export GPU_COUNT=1
export PIPES_PER_GPU=8

CHUNK=$(printf "%03d" ${SLURM_ARRAY_TASK_ID})
export IMAGE_LIST=${TRAINING_DIR}/lists/chunk_${CHUNK}.txt
export OUT_DIR=${TRAINING_DIR}/output/chunk_${CHUNK}
mkdir -p ${OUT_DIR}


cd ${TRAINING_DIR}
module load apptainer
apptainer exec --nv ${VIAME_CONTAINER} bash -c "
    source ${VIAME_INSTALL}/setup_viame.sh
    python ${VIAME_INSTALL}/configs/process_video.py \
        -l ${IMAGE_LIST} \
        -p ${TRAINING_DIR}/category_models/run.pipe \
        -o ${OUT_DIR} \
        --no-reset-prompt \
        -gpus ${GPU_COUNT} \
        -pipes-per-gpu ${PIPES_PER_GPU}
"
