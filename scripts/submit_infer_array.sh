#!/bin/bash
#SBATCH -c12 --mem-per-cpu=10000 --gpus-per-node=h100:1 --time=3:0:0
#SBATCH --array=0-39%8
#SBATCH --output=logs/infer_%A_%a.out

module load apptainer

PROJECT_DIR=/project/6112925/Project_Loutet_Shadowgraph
export TRAINING_DIR=${PROJECT_DIR}/Training-20260921
export VIAME_CONTAINER=${PROJECT_DIR}/viame.sif
export VIAME_INSTALL=/opt/noaa/viame
export GPU_COUNT=1
export PIPES_PER_GPU=8

CHUNK=$(printf "%03d" ${SLURM_ARRAY_TASK_ID})
export IMAGE_LIST=${TRAINING_DIR}/lists/chunk_${CHUNK}.txt
export OUT_DIR=${TRAINING_DIR}/output/chunk_${CHUNK}
mkdir -p ${OUT_DIR}

cd ${TRAINING_DIR}
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
