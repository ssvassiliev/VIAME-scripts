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

#### 1. Prepare the Working Directory and Input Image List

Start by creating an empty directory for your inference run. You will store `inference_images.txt` and the inference outputs in this directory.

For example:

```bash
mkdir inference
cd inference
```

Next, create a list of images that you want to process with the trained model.

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

