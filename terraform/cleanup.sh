#!/bin/bash
# cleanup.sh

# Remove existing directories and files
rm -rf /home/rob/repos/infrastructure/terraform/logging/config
rm -rf /home/rob/repos/infrastructure/terraform/logging/loki-data

# Create parent directories
mkdir -p /home/rob/repos/infrastructure/terraform/logging/config
mkdir -p /home/rob/repos/infrastructure/terraform/logging/loki-data
