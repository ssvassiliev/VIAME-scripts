## VIAME Scripts

### Training

#### 1. Prepare the Training Dataset

Create a project directory containing the training images, their annotations, and a label file.

Example directory structure:

```text
Project-XXX/              
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

**Important:** Keep the image directory and its annotation CSV file in the same project directory. The CSV filename should match the image directory name, excluding the extension.


### Inference

Set the following variables before continuing. They will be referenced throughout the steps below.
```
PROJECT_DIR       # Root directory
TRAINING_DIR      # Path to the directory containing category_models
IMAGE_LIST        # Path to inference_images.txt
VIAME_CONTAINER.  # Path to viame.sif
```

Create a list of images that you want to process with the trained model.

**Option 1: Images in a single directory**

If all images are in one directory, navigate to that directory and create the list:

```bash
cd /path/to/images
find . -maxdepth 1 -type f > /path/to/inference/inference_images.txt
```

Replace `/path/to/images` with the directory containing your images and `/path/to/inference` with your inference working directory.

This command lists all files in the image directory, excluding files in subdirectories.

**Option 2: Images in multiple directories**

If your images are organized into subdirectories, use:

```bash
find ${PROJECT_DIR} -type f > /path/to/inference/inference_images.txt
```

Replace `${PROJECT_DIR}` with the path to the directory containing your images. This command lists all files in that directory and its subdirectories.

**Option 3: Filter the list by file extension**

The commands above include all file types, not just images. If necessary, use `grep` to keep only files with the desired extension. For example, to keep only JPEG images:

```bash
grep -i '\.jpg$' /path/to/inference/inference_images.txt \
    > /path/to/inference/jpg_images.txt
```

If you use the filtered list, specify `jpg_images.txt` instead of `inference_images.txt` when running inference.

## Generate run pipe

Run these from `${TRAINING_DIR}` (the directory that contains `category_models/`).

1. Copy the pipeline template out of the container:

```bash
cd ${TRAINING_DIR}
apptainer exec ${VIAME_CONTAINER} \
    cat /opt/noaa/viame/configs/pipelines/templates/detector_default.pipe \
    > category_models/detector_default.pipe
```

2. Extract the detector block (everything after `:: image_object_detector` up to the first `connect`):

```bash
awk '/:: image_object_detector/{f=1;next} /^connect/{f=0} f' \
    category_models/detector.pipe > category_models/detector_block.txt
```

3. Insert the block in place of the `[-DETECTOR-IMPL-]` placeholder:

```bash
sed -e '/\[-DETECTOR-IMPL-\]/{r category_models/detector_block.txt' -e 'd}' \
    category_models/detector_default.pipe > category_models/run.pipe
```

4. Verify. The diff should show only the detector block replacing the placeholder:

```bash
diff -u category_models/detector_default.pipe category_models/run.pipe
```

Regenerate `run.pipe` after every retraining, since `detector.pipe` changes.

## Run inference

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

```text
PPROJECT_DIR/              
├── TRAINING_DIR/            
│   ├── category_models/
│   ├── deep_training/
│   ├─── test_output/
│   └── IMAGE_LIST
└── TRAINING-DATA_DIR       
    ├── dataset_01/
    │   ├── image001.jpg
    │   ├── image002.jpg
    │   └── ...
    ├── dataset_01.csv         
    └── labels.txt    
```
