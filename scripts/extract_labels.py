import csv
import sys

def extract_labels(csv_path):
    species = set()
    with open(csv_path, newline='') as f:
        reader = csv.reader(f)
        for row in reader:
            if not row:
                continue
            if row[0].startswith('#') or row[0].startswith('1: Detection'):
                continue
            # columns 0-8 are fixed (9 required fields, 0-indexed 0-8)
            # columns 9+ come in (species, confidence) pairs, until we hit
            # something that isn't a plausible species/confidence pair
            i = 9
            while i + 1 < len(row):
                name = row[i].strip()
                conf = row[i + 1].strip()
                if not name:
                    break
                # attributes are usually wrapped like (kv) key value, or start with '('
                if name.startswith('('):
                    break
                # confidence should look numeric
                try:
                    float(conf)
                except ValueError:
                    break
                species.add(name)
                i += 2
    return sorted(species)

if __name__ == "__main__":
    csv_path = sys.argv[1]
    out_path = sys.argv[2] if len(sys.argv) > 2 else "labels.txt"
    labels = extract_labels(csv_path)
    with open(out_path, "w") as f:
        for l in labels:
            f.write(l + "\n")
    print(f"Found {len(labels)} unique labels:")
    for l in labels:
        print(" -", l)
    print(f"Written to {out_path}")
