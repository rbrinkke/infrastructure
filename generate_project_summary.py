import os
from datetime import datetime

# Specificeer mappen en extensies die je relevant vindt
relevant_directories = [
    "ansible",
    "services",
    "terraform",
]
relevant_files = [
    "docker-compose.yml",
    "Dockerfile",
    "README.md",
    "update_github.sh",
]
exclude_directories = ["venv"]  # Uitsluiten om onnodige bestanden te vermijden

# Output bestand
output_file = "project_summary.txt"

def gather_files(base_path, relevant_dirs, relevant_files, exclude_dirs):
    collected_files = []
    for root, dirs, files in os.walk(base_path):
        # Filter ongewenste directories
        dirs[:] = [d for d in dirs if d not in exclude_dirs]
        
        # Voeg specifieke bestanden toe
        for file in files:
            file_path = os.path.relpath(os.path.join(root, file), base_path)
            if (
                any(file_path.startswith(d) for d in relevant_dirs)  # Bestanden in relevante mappen
                or file in relevant_files  # Specifieke bestanden
            ):
                collected_files.append(file_path)
    return collected_files

def write_summary(file_list, base_path, output_file):
    with open(output_file, "w") as f:
        # Tijd en datum van draaien
        f.write(f"# Project Environment Summary\n")
        f.write(f"# Generated on: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n\n")
        
        for file_path in file_list:
            full_path = os.path.join(base_path, file_path)
            f.write(f"### File: {file_path}\n")
            f.write(f"---\n")
            try:
                with open(full_path, "r") as content_file:
                    content = content_file.read()
                    f.write(content + "\n")
            except Exception as e:
                f.write(f"[ERROR] Could not read file: {e}\n")
            f.write("\n")

if __name__ == "__main__":
    base_path = os.getcwd()  # Gebruik de huidige werkdirectory
    files_to_include = gather_files(base_path, relevant_directories, relevant_files, exclude_directories)
    write_summary(files_to_include, base_path, output_file)
    print(f"Project summary has been written to {output_file}")

