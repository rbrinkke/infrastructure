name: CI/CD Pipeline

on:
  push:
    branches:
      - main

jobs:
  deploy:
    runs-on: self-hosted
    env:
      DOCKER_USERNAME: ${{ secrets.DOCKER_USERNAME }}
      DOCKER_PASSWORD: ${{ secrets.DOCKER_PASSWORD }}
      SSH_KEY: ${{ secrets.SSH_KEY }}
      VAULT_ADDR: ${{ secrets.VAULT_ADDR }}
      VAULT_TOKEN: ${{ secrets.VAULT_TOKEN }}
      REMOTE_HOST: "192.168.178.183"
      REMOTE_USER: "swarm_user"
      REMOTE_PATH: "/home/rob/repos/infrastructure"

    steps:
      - name: Checkout Code
        uses: actions/checkout@v3

      - name: Setup SSH Agent
        uses: webfactory/ssh-agent@v0.5.4
        with:
          ssh-private-key: ${{ env.SSH_KEY }}

      - name: Debug Docker Login
        run: |
          set -x
          echo "$DOCKER_PASSWORD" | docker login -u "$DOCKER_USERNAME" --password-stdin 2>&1 | tee docker_login.log

      # Check de status van Vault en sla JSON output op
      - name: Check Vault Status
        run: |
          set -x
          export VAULT_ADDR="${{ env.VAULT_ADDR }}"
          export VAULT_TOKEN="${{ env.VAULT_TOKEN }}"
          vault status -format=json 2>&1 | tee vault_status.json

      # Controleer of Vault sealed is en zet een output variabele
      - name: Determine if Vault is sealed
        id: check_if_vault_is_sealed
        run: |
          set -x
          sealed=$(jq -r '.sealed' vault_status.json)
          if [ "$sealed" = "true" ]; then
            echo "Vault is sealed."
            echo "sealed=true" >> $GITHUB_OUTPUT
          else
            echo "Vault is already unsealed."
            echo "sealed=false" >> $GITHUB_OUTPUT
          fi

      # Alleen unsealen als vault sealed=true is
      - name: Unseal Vault
        if: steps.check_if_vault_is_sealed.outputs.sealed == 'true'
        run: |
          set -x
          export VAULT_ADDR="${{ env.VAULT_ADDR }}"
          vault operator unseal ${{ secrets.VAULT_UNSEAL_KEY_1 }}
          vault operator unseal ${{ secrets.VAULT_UNSEAL_KEY_2 }}
          vault operator unseal ${{ secrets.VAULT_UNSEAL_KEY_3 }}

      # (Optioneel) Check nogmaals na unseal
      - name: Check Vault Status after Unseal
        if: steps.check_if_vault_is_sealed.outputs.sealed == 'true'
        run: |
          set -x
          export VAULT_ADDR="${{ env.VAULT_ADDR }}"
          vault status 2>&1 | tee vault_status_after_unseal.log

      - name: Initialize Docker Swarm
        run: |
          set -x
          docker swarm init 2>&1 | tee docker_swarm_init.log || echo "Docker Swarm is mogelijk al geïnitialiseerd"

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v2
        with:
          terraform_version: 1.4.0

      - name: Terraform Init
        working-directory: ./terraform
        run: |
          set -x
          export TF_LOG=TRACE
          export TF_LOG_PATH=terraform_init.log
          export TF_INPUT=false
          terraform init -no-color 2>&1 | tee -a terraform_init.log

      - name: Terraform Apply
        working-directory: ./terraform
        run: |
          set -x
          export TF_LOG=TRACE
          export TF_LOG_PATH=terraform_apply.log
          export TF_INPUT=false
          terraform apply -auto-approve -input=false -no-color 2>&1 | tee -a terraform_apply.log

      - name: Run Ansible Playbook with more verbosity
        working-directory: ./ansible
        run: |
          set -x
          export ANSIBLE_LOG_PATH=ansible_debug.log
          ansible-playbook playbook.yml -i inventory.yml -vvvv 2>&1 | tee -a ansible_debug.log

      - name: Deploy Docker Stack
        run: |
          set -x
          ssh -o StrictHostKeyChecking=no $REMOTE_USER@$REMOTE_HOST "
            cd $REMOTE_PATH &&
            docker stack deploy -c docker-compose.yml infrastructure_stack
          " 2>&1 | tee docker_stack_deploy.log

      - name: Upload Logs
        uses: actions/upload-artifact@v3
        with:
          name: build-logs
          path: |
            ./terraform/terraform_init.log
            ./terraform/terraform_apply.log
            ./ansible/ansible_debug.log
            ./docker_login.log
            ./docker_swarm_init.log
            ./docker_stack_deploy.log
            ./vault_status.json
            ./vault_status_after_unseal.log

