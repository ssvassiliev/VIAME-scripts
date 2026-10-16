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

#### 1. Prepare the Input Image List

For inference, you need to create a list of images that you want to process with the trained model.

**Option 1: Images in a single directory**

If all images are in one directory, first navigate to that directory and create the list:

```bash
cd /path/to/images
find . -maxdepth 1 -type f > inference_images.txt
```

This creates `inference_images.txt`, containing the names of all files in the current directory (excluding files in subdirectories).

**Option 2: Images in multiple directories**

If your images are organized into subdirectories, use:

```bash
find ${PROJECT_DIR} -type f > inference_images.txt
```

Replace `${PROJECT_DIR}` with the path to your project directory. This command lists all files in the project directory and its subdirectories.

**Note:** These commands include all file types, not just images. Make sure the list contains only files that the inference script can process.

**Option 3: Filter the list by file extension**

If the list contains files other than images, use grep to keep only files with the desired extension. For example, to keep only JPEG images:

```bash
grep -i '\.jpg$' inference_images.txt > jpg_images.txt
```

