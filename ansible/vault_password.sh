#!/bin/bash
# Script to retrieve Ansible Vault password from Jenkins Credential
# Usage: vault_password.sh

# Read vault password from Jenkins credential
# This file should be in Jenkins Credentials and passed as environment variable
echo "${ANSIBLE_VAULT_PASSWORD}"

