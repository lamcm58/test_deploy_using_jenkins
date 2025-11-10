#!/bin/bash
# Script to check and install Ansible on Jenkins server/agent

echo "=== Checking Ansible Installation ==="

# Check if ansible-playbook is available
if command -v ansible-playbook &> /dev/null; then
    echo "✓ ansible-playbook found: $(command -v ansible-playbook)"
    ansible-playbook --version
    exit 0
fi

# Check common locations
echo "Checking common locations..."
for path in /usr/local/bin/ansible-playbook \
            /usr/bin/ansible-playbook \
            /opt/homebrew/bin/ansible-playbook \
            ~/.local/bin/ansible-playbook; do
    if [ -f "$path" ]; then
        echo "✓ Found at: $path"
        "$path" --version
        exit 0
    fi
done

echo "✗ Ansible not found!"
echo ""
echo "To install Ansible, run one of the following:"
echo ""
echo "1. Using pip3 (recommended):"
echo "   pip3 install ansible"
echo ""
echo "2. Using pip (if pip3 not available):"
echo "   pip install ansible"
echo ""
echo "3. Using apt (Ubuntu/Debian):"
echo "   sudo apt update"
echo "   sudo apt install ansible"
echo ""
echo "4. Using yum (CentOS/RHEL):"
echo "   sudo yum install ansible"
echo ""
echo "5. Using homebrew (macOS):"
echo "   brew install ansible"
echo ""
echo "After installation, verify with:"
echo "   ansible-playbook --version"

exit 1

