#!/usr/bin/env python3
import os
import re
from pathlib import Path

def update_terraform_files(directory):
    """
    Recursively find and update Terraform files to use kreuzwerker/docker provider
    """
    # Pattern to match provider "docker" blocks
    provider_pattern = re.compile(r'provider\s+"docker"\s*{([^}]*)}', re.MULTILINE | re.DOTALL)
    
    # Pattern to match required_providers blocks
    required_pattern = re.compile(r'(required_providers\s*{[^}]*?)(docker\s*=\s*{[^}]*?})', re.MULTILINE | re.DOTALL)
    
    # Counter for modified files
    modified_files = 0
    
    # Walk through all directories
    for tf_file in Path(directory).rglob("*.tf"):
        file_modified = False
        with open(tf_file, 'r') as f:
            content = f.read()
        
        # Update provider blocks
        new_content = provider_pattern.sub(
            'provider "docker" {\n  source = "kreuzwerker/docker"\n\g<1>}',
            content
        )
        
        # Update required_providers blocks
        def required_replacement(match):
            block_start = match.group(1)
            if "kreuzwerker/docker" not in match.group(2):
                return f'{block_start}docker = {{\n      source = "kreuzwerker/docker"\n    }}'
            return match.group(0)
        
        new_content = required_pattern.sub(required_replacement, new_content)
        
        # If content changed, write back to file
        if new_content != content:
            with open(tf_file, 'w') as f:
                f.write(new_content)
            modified_files += 1
            print(f"Updated: {tf_file}")
    
    return modified_files

def main():
    # Get current directory
    current_dir = os.getcwd()
    
    print(f"Starting scan in: {current_dir}")
    print("Looking for Terraform files to update...")
    
    # Create backup
    backup_command = f"tar -czf terraform_backup_$(date +%Y%m%d_%H%M%S).tar.gz $(find . -name '*.tf')"
    print("Creating backup...")
    os.system(backup_command)
    
    # Update files
    modified = update_terraform_files(current_dir)
    
    print(f"\nComplete! Modified {modified} files.")
    if modified > 0:
        print("Please review the changes and run 'terraform init' again.")
    else:
        print("No files needed updating.")

if __name__ == "__main__":
    main()
