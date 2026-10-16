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
