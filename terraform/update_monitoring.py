#!/usr/bin/env python3
import os
from pathlib import Path

def check_and_update_monitoring():
    """Check and update the monitoring module's provider configuration"""
    monitoring_dir = Path("monitoring")
    
    # First, check if there's already a terraform block
    has_terraform_block = False
    has_provider_block = False
    provider_file_path = None
    
    # Check all .tf files in monitoring directory
    for tf_file in monitoring_dir.glob("*.tf"):
        with open(tf_file, 'r') as f:
            content = f.read()
            if 'terraform {' in content:
                has_terraform_block = True
            if 'provider "docker"' in content:
                has_provider_block = True
                provider_file_path = tf_file
    
    # If no terraform block exists, create a new file
    if not has_terraform_block:
        new_content = '''terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}
'''
        with open(monitoring_dir / "versions.tf", 'w') as f:
            f.write(new_content)
        print("Created new versions.tf with required_providers block")
    
    # If there's a provider block, check and clean it
    if provider_file_path:
        with open(provider_file_path, 'r') as f:
            content = f.read()
        
        # Remove any source = "..." from provider block
        if 'source = "' in content:
            lines = content.split('\n')
            cleaned_lines = [line for line in lines if 'source = "' not in line]
            with open(provider_file_path, 'w') as f:
                f.write('\n'.join(cleaned_lines))
            print(f"Cleaned provider configuration in {provider_file_path}")

def main():
    print("Checking monitoring module...")
    check_and_update_monitoring()
    print("\nDone! Please run 'terraform init' again.")

if __name__ == "__main__":
    main()
