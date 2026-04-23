#!/usr/bin/env python3
import os
import sys
import yaml

def split_yaml(file_path, output_dir):
    # Create the output directory if it doesn't exist.
    os.makedirs(output_dir, exist_ok=True)

    # Load all YAML documents from the file.
    with open(file_path, 'r') as f:
        documents = list(yaml.safe_load_all(f))
    
    # Process each document and write to a separate file.
    for idx, doc in enumerate(documents, start=1):
        if doc is None:
            continue

        # Use a specific name for Namespace objects or metadata.name otherwise.
        kind = doc.get("kind", "").lower()
        if kind == "namespace":
            base_name = "namespace"
        else:
            base_name = doc.get("metadata", {}).get("name", f"doc{idx}")

        # Format file name with a two-digit prefix.
        file_name = f"{idx:02d}-{base_name}.yaml"
        out_path = os.path.join(output_dir, file_name)
        
        # Write the YAML document to the file.
        with open(out_path, 'w') as out_file:
            yaml.dump(doc, out_file, sort_keys=False)
        print(f"Wrote {out_path}")

if __name__ == '__main__':
    if len(sys.argv) != 3:
        print("Usage: python split_yaml.py <input_yaml_file> <output_directory>")
        sys.exit(1)

    input_file = sys.argv[1]
    output_directory = sys.argv[2]
    split_yaml(input_file, output_directory)
