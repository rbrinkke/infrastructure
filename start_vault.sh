docker run -d \
    --name vault-permanent \
    -p 8600:8600 \
    -v /home/rob/repos/infrastructure/terraform/vault/vault-data:/vault/file \
    -v /home/rob/repos/infrastructure/terraform/vault/config:/vault/config \
    -v /home/rob/repos/infrastructure/terraform/vault/logs:/vault/logs \
    -e 'VAULT_ADDR=http://0.0.0.0:8600' \
    -e 'VAULT_API_ADDR=http://0.0.0.0:8600' \
    --cap-add=IPC_LOCK \
    hashicorp/vault:1.18.2 \
    vault server -config=/vault/config/vault.hcl
