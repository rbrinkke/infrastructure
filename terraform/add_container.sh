#!/bin/bash

# Pad naar Terraform configuratie
TERRAFORM_DIR="/home/rob/repos/infrastructure/terraform"
EXCLUDED_CONTAINERS=("vault-permanent")  # Containers om uit te sluiten
IGNORED_DIRS=("vault-data" ".terraform")  # Mappen om te negeren

# Logbestand
LOGFILE="debug_log.txt"
echo "=== Start script op $(date) ===" > "$LOGFILE"

cd "$TERRAFORM_DIR" || { echo "Terraform directory niet gevonden!"; exit 1; }

# Haal actieve Docker-containers op
docker_containers=$(docker ps --format "{{.Names}}")
echo "Docker containers:" >> "$LOGFILE"
echo "$docker_containers" >> "$LOGFILE"

for container in $docker_containers; do
    if [[ ! " ${EXCLUDED_CONTAINERS[@]} " =~ " ${container} " ]]; then
        echo "Controleer container: $container" | tee -a "$LOGFILE"

        # Zoek naar configuratie in relevante Terraform-bestanden
        config_exists=$(find . -type f -name "*.tf" -exec grep -rl "docker_container.*\"$container\"" {} + 2>/dev/null)
        echo "Gevonden configuratie: $config_exists" | tee -a "$LOGFILE"

        if [[ -z "$config_exists" ]]; then
            echo "Configuratie ontbreekt voor $container. Handmatige configuratie vereist." | tee -a "$LOGFILE"
            continue
        fi

        # Bepaal de module (indien aanwezig)
        module_path=$(dirname "$config_exists" | sed 's|^\./||')
        module_prefix=""
        if [[ "$module_path" != "." ]]; then
            module_prefix="module.$module_path."
        fi
        echo "Module prefix: $module_prefix" | tee -a "$LOGFILE"

        # Probeer te importeren
        echo "Container ontbreekt in Terraform state: $container. Probeer te importeren..." | tee -a "$LOGFILE"
        import_command="terraform import ${module_prefix}docker_container.$container $container"
        echo "Uitvoeren: $import_command" | tee -a "$LOGFILE"
        eval "$import_command" 2>&1 | tee -a "$LOGFILE"
    fi
done

echo "Script voltooid op $(date)." | tee -a "$LOGFILE"

