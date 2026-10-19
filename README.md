# VIAME Scripts

## Training

### 1. Prepare the Training Dataset

Create a project directory containing the training images, their annotations, and a label file.


Your project directory should have the following structure:

```text
PPROJECT_DIR/              
├── TRAINING_DIR/            
└── TRAINING-DATA_DIR       
    ├── dataset_01/
    │   ├── image001.jpg
    │   ├── image002.jpg
    │   └── ...
    ├── dataset_01.csv         
    └── labels.txt    
```

**File descriptions:** 
- `dataset_01/`: Contains the training images.
- `dataset_01.csv`: Contains the annotations for the images in `dataset_01/`. 
- `labels.txt`: Lists the object categories used in the annotations.

**Important:** 
- Keep the image directory and its annotation CSV file in the same project directory. 
- The CSV filename should match the image directory name, excluding the extension.

### 2. Run training

```bash
cd ${TRAINING_DIR}
sbatch /path/to/submit_train.sh
```

## Inference
### 1. Describe your environment

#### Directory structure
Your project directory after training should have the following structure:

```text
PPROJECT_DIR/              
├── TRAINING_DIR/            
│   ├── category_models/
│   │   ├── model_evaluation/
│   │   ├── detector.pipe
│   │   └── trained_detector.zip
│   └── deep_training/
└── TRAINING-DATA_DIR       
    ├── dataset_01/
    │   ├── image001.jpg
    │   ├── image002.jpg
    │   └── ...
    ├── dataset_01.csv         
    └── labels.txt    
```

Set the following variables before continuing. They will be referenced throughout the steps below.
```
PROJECT_DIR       # Path to the project root directory
TRAINING_DIR      # Path to the directory containing category_models
IMAGE_LIST        # Path to inference_images.txt
VIAME_CONTAINER   # Path to the VIAME container (viame.sif)
```

Example:

```bash
export PROJECT_DIR=/project/6112925/Project_Loutet_Shadowgraph
export TRAINING_DIR=${PROJECT_DIR}/Training-20260921
export IMAGE_LIST=${TRAINING_DIR}/inference_images.txt
export VIAME_CONTAINER=${PROJECT_DIR}/viame.sif
```

### 2. Create a list of images that you want to process with the trained model.

If all images are in one directory, navigate to that directory and create the list:

```bash
cd /path/to/images
find $(pwd -P) -maxdepth 1 -type f > ${TRAINING_DIR}/inference_images.txt
```

This command lists all files in the image directory, excluding files in subdirectories. 

**Optionally filter the list by file extension**

The commands above include all file types, not just images. If necessary, use `grep` to keep only files with the desired extension. For example, to keep only JPEG images:

```bash
grep -i '\.jpg$' /path/to/inference/inference_images.txt \
    > /path/to/inference/jpg_images.txt
```

If you use the filtered list, specify `jpg_images.txt` instead of `inference_images.txt` when running inference. 


### 3. Generate run pipe

The file category_models/detector.pipe contains the trained-model detector block. To create a complete inference pipeline, extract this block and insert it into the default inference template.

Run the following commands from `${TRAINING_DIR}` (the directory that contains `category_models/`).

#### 1. Copy the default pipeline template from the container

```bash
cd ${TRAINING_DIR}
apptainer exec ${VIAME_CONTAINER} \
    cat /opt/noaa/viame/configs/pipelines/templates/detector_default.pipe \
    > category_models/detector_default.pipe
```

#### 2. Extract the trained detector block  

 Extract everything after :: image_object_detector up to the first connect statement:

```bash
awk '/:: image_object_detector/{f=1;next} /^connect/{f=0} f' \
    category_models/detector.pipe > category_models/detector_block.txt
```

#### 3. Insert the detector block into the template.

Replace the [-DETECTOR-IMPL-] placeholder with the extracted detector block to generate the complete inference pipeline, run.pipe:


```bash
sed -e '/\[-DETECTOR-IMPL-\]/{r category_models/detector_block.txt' -e 'd}' \
    category_models/detector_default.pipe > category_models/run.pipe
```

#### 4. Verify the generated pipeline

Compare the original template with the generated pipeline:

```bash
diff -u category_models/detector_default.pipe category_models/run.pipe
```

The diff should show the detector block replacing the [-DETECTOR-IMPL-] placeholder, with the rest of the template unchanged.

**Important:** regenerate `run.pipe` after every retraining, since `detector.pipe` changes.


Your project directory after these steps should have the following structure:

```text
PPROJECT_DIR/              
├── TRAINING_DIR/            
│   ├── category_models/
│   │   ├── model_evaluation/
│   │   ├── detector.pipe
│   │   ├── detector_default.pipe
│   │   ├── detector_block.pipe
│   │   ├── run.pipe
│   │   └── trained_detector.zip
│   ├── deep_training/
│   ├── test_output/
│   └── IMAGE_LIST 
└── TRAINING-DATA_DIR       
    ├── dataset_01/
    │   ├── image001.jpg
    │   ├── image002.jpg
    │   └── ...
    ├── dataset_01.csv         
    └── labels.txt    
```

### 5. Run inference

```bash
cd ${TRAINING_DIR}
mkdir -p ${TRAINING_DIR}/output

apptainer exec --nv ${VIAME_CONTAINER} bash -c "
    source ${VIAME_INSTALL}/setup_viame.sh
    python ${VIAME_INSTALL}/configs/process_video.py \
        -l ${IMAGE_LIST} \
        -p ${TRAINING_DIR}/category_models/run.pipe \
        -o ${TRAINING_DIR}/output \
        --no-reset-prompt \
        -gpus ${GPU_COUNT} \
        -pipes-per-gpu ${PIPES_PER_GPU}
"
```

(This runs inside the container after `source ${VIAME_INSTALL}/setup_viame.sh`, as in your job script.)

Submit pipeline with:

```bash
sbatch /path/to/submit_infer.sh
```

### Parallel inference runs 

To estimate the total processing, run a short test job on about 1,000 images and check the job’s wall time. Always run a short test before submitting a large job.

Benchmark a random sample, not the first N images. Detection density and image content vary through a dive, so a contiguous block can mislead.

```bash
shuf -n 1000 all_images.txt > inference_images_1000.txt
```

Let it finish, then read the time from Slurm: 

```bash
sacct -X -j <jobid> --format=JobID,State,Elapsed
```
Don’t judge progress by CSV line counts in the output file, because empty images write nothing and output may only be complete at the end.

If the estimated runtime is several days, consider splitting the dataset into smaller chunks and submitting them as an array job. Chunks that take roughly 4–10 hours each can run in parallel, and shorter jobs generally start sooner. If a job fails, you’ll also have less work to repeat.

Use split to make fixed-size lists, then a SLURM job array so each array task processes one list. That’s one sbatch call and scales to however many chunks you have.

1. Make the lists from $IMAGE_LIST:

```bash
cd $TRAINING_DIR
mkdir -p lists
split -l 5000 -d -a 3 --additional-suffix=.txt inference_images.txt lists/chunk_
```

This produces chunk_000.txt, chunk_001.txt, and so on, which means 40 chunks of 5,000 for 200,000 images. split handles filenames with spaces fine because it splits on lines.

2. Run inference using array job script `submit_infer_array.sh`.

Submit pipeline with:

```bash
mkdir -p output
sbatch /path/to/submit_infer_array.sh
```

Important: Keep the directory names `lists` and `output` unchanged. These names are hardcoded in the array submission script and must match exactly.

In the example script `--array=0-39` runs tasks 0 to 39.Set the upper bound to the number of chunks minus one: `ls lists | wc -l, minus 1`.

Each chunk writes to its own output directory, so tasks never overwrite each other. 

If you have a different number of chunks you can pass it at submit time instead of editing the script:

```bash
sbatch --array=0-$((N-1)) infer_array.sh
```
where N is the number of chunks

3. Rerun failures. 

Check what finished:
```bash
sacct -j <jobid> --format=JobID,State,Elapsed,MaxRSS | grep -v COMPLETED
```
Then resubmit only the failed indices, for example 
```
sbatch --array=3,17,22 submit_infer_array.sh
```

**Merging**. Once done, you can merge the CSVs. Keep one header and renumber the track IDs, because each chunk restarts IDs from 0. Here’s a sketch, which assumes each chunk wrote computed_detections.csv:

```bash
head -n 2 output/chunk_000/computed_detections.csv > merged.csv
for f in output/chunk_*/computed_detections.csv; do grep -v '^#' "$f"; done >> merged.csv
```  
