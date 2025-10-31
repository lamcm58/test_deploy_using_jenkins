#!/bin/bash
# Helper script to migrate from Jenkins Credentials to Ansible Vault
# This script helps create vault files for each environment

set -e

echo "🔐 Ansible Vault Migration Helper"
echo "================================"
echo ""

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if ansible-vault is installed
if ! command -v ansible-vault &> /dev/null; then
    echo "❌ ansible-vault not found. Please install Ansible first."
    exit 1
fi

# Function to create vault file for an environment
create_vault_file() {
    local env=$1
    local vault_file="group_vars/${env}/vault.yml"
    
    echo -e "${YELLOW}Creating vault file for ${env}...${NC}"
    
    # Check if file already exists and is encrypted
    if [ -f "$vault_file" ]; then
        echo "⚠️  File $vault_file already exists."
        read -p "Do you want to overwrite it? (y/N): " overwrite
        if [[ ! $overwrite =~ ^[Yy]$ ]]; then
            echo "Skipping $env..."
            return
        fi
    fi
    
    # Create directory if needed
    mkdir -p "group_vars/${env}"
    
    # Create temporary unencrypted file
    cat > "${vault_file}.tmp" <<EOF
---
# Database credentials for ${env} environment
db_host: ${env}_db_host_here
db_name: laravel_${env}
db_user: ${env}_user
db_password: ${env}_password_here

# Ansible become password
ansible_become_password: ${env}_become_password_here

# Add other sensitive variables as needed
# app_key: base64:your_app_key_here
# redis_password: your_redis_password_here
EOF
    
    echo ""
    echo "📝 Please edit the file and replace placeholders with actual values:"
    echo "   File: ${vault_file}.tmp"
    echo ""
    read -p "Press Enter when you're done editing..."
    
    # Encrypt the file
    echo ""
    echo "🔐 Encrypting vault file..."
    ansible-vault encrypt "${vault_file}.tmp" --output "${vault_file}"
    rm "${vault_file}.tmp"
    
    echo -e "${GREEN}✅ Created encrypted vault file: ${vault_file}${NC}"
    echo ""
}

# Main migration process
echo "This script will help you create Ansible Vault files for each environment."
echo ""
echo "You'll need to:"
echo "1. Edit each vault file with your actual credentials"
echo "2. Encrypt it with ansible-vault"
echo "3. Add the vault password to Jenkins Credentials"
echo ""

read -p "Do you want to proceed? (y/N): " proceed
if [[ ! $proceed =~ ^[Yy]$ ]]; then
    echo "Cancelled."
    exit 0
fi

# Create vault files for each environment
for env in develop staging production; do
    if [ -d "group_vars/${env}" ]; then
        create_vault_file "$env"
    fi
done

echo ""
echo -e "${GREEN}🎉 Migration helper completed!${NC}"
echo ""
echo "Next steps:"
echo "1. Review encrypted vault files in group_vars/*/vault.yml"
echo "2. Add vault password to Jenkins Credentials (ID: ansible-vault-password)"
echo "3. Update Jenkinsfile to use Ansible Vault"
echo "4. Test deployment with develop environment first"
echo ""

