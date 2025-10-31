#!/bin/bash
# Script to retrieve Ansible Vault password from Jenkins Credential
# Usage: vault_password.sh

# Read vault password from Jenkins credential
# This file should be in Jenkins Credentials and passed as environment variable

# Check if environment variable is set
if [ -z "${ANSIBLE_VAULT_PASSWORD}" ]; then
    echo "ERROR: ANSIBLE_VAULT_PASSWORD environment variable is not set" >&2
    exit 1
fi

# Output the vault password (Ansible will read this)
echo "${ANSIBLE_VAULT_PASSWORD}"

