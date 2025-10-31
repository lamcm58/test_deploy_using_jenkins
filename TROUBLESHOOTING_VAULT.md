# 🔧 Troubleshooting Ansible Vault Decryption Issues

## Lỗi: "Decryption failed (no vault secrets were found)"

Lỗi này xảy ra khi Ansible không thể decrypt vault file. Có nhiều nguyên nhân:

---

## ✅ Giải pháp 1: Kiểm tra Vault Password trong Jenkins

### Bước 1: Verify Jenkins Credential

1. Vào Jenkins → **Manage Jenkins** → **Manage Credentials**
2. Tìm credential với ID: `ansible-vault-password`
3. Verify password có đúng với password bạn dùng khi encrypt không

**Cách kiểm tra:**
```bash
# Test decrypt local
cd ansible
export ANSIBLE_VAULT_PASSWORD="your_password_from_jenkins"
ansible-vault view group_vars/develop/vault.yml
```

Nếu decrypt được → Password đúng ✅  
Nếu không decrypt được → Password sai ❌

### Bước 2: Update Jenkins Credential nếu password sai

1. Vào Jenkins Credentials
2. Update password với password đúng
3. Hoặc encrypt lại vault file với password mới

---

## ✅ Giải pháp 2: Sửa vault_password.sh Script

Vấn đề có thể là script không nhận được environment variable.

### Option A: Dùng script cải thiện (đã update)

File `ansible/vault_password.sh` đã được update với error checking.

### Option B: Dùng inline script trong Jenkinsfile

Thay `--vault-password-file ansible/vault_password.sh` bằng:

```groovy
sh '''
    # Create temp script inline
    echo '#!/bin/bash' > /tmp/vault_pass.sh
    echo "echo '${VAULT_PASS}'" >> /tmp/vault_pass.sh
    chmod +x /tmp/vault_pass.sh
    
    ansible-playbook -i ansible/inventory ansible/deploy.yml \
        --vault-password-file /tmp/vault_pass.sh \
        --extra-vars "env=${DEPLOY_ENV}" \
        --limit ${DEPLOY_ENV}
    
    rm -f /tmp/vault_pass.sh
'''
```

---

## ✅ Giải pháp 3: Pass Vault Password Trực tiếp

### Sử dụng stdin (không khuyến nghị vì lộ trong logs)

```groovy
sh '''
    echo "${VAULT_PASS}" | ansible-playbook -i ansible/inventory ansible/deploy.yml \
        --vault-password-file /dev/stdin \
        --extra-vars "env=${DEPLOY_ENV}" \
        --limit ${DEPLOY_ENV}
'''
```

**⚠️ Cảnh báo:** Password có thể hiện trong logs!

---

## ✅ Giải pháp 4: Debug Vault Password Script

Thêm debug vào Jenkinsfile:

```groovy
sh '''
    export ANSIBLE_VAULT_PASSWORD="${VAULT_PASS}"
    
    # Debug: Test script
    echo "Testing vault_password.sh..."
    ansible/vault_password.sh
    
    # Debug: Check environment variable
    echo "ANSIBLE_VAULT_PASSWORD is set: ${ANSIBLE_VAULT_PASSWORD:+YES}"
    
    # Run playbook
    ansible-playbook -i ansible/inventory ansible/deploy.yml \
        --vault-password-file ansible/vault_password.sh \
        --extra-vars "env=${DEPLOY_ENV}" \
        --limit ${DEPLOY_ENV}
'''
```

---

## ✅ Giải pháp 5: Re-encrypt Vault File

Nếu password bị mất hoặc không nhớ:

### Re-encrypt với password mới

```bash
cd ansible

# Nếu biết password cũ
ansible-vault rekey group_vars/develop/vault.yml
# Nhập password cũ, rồi password mới

# Hoặc decrypt và encrypt lại
ansible-vault decrypt group_vars/develop/vault.yml
# (Nhập password cũ để decrypt)

# Tạo password mới
ansible-vault encrypt group_vars/develop/vault.yml
# (Nhập password mới)

# Update Jenkins credential với password mới
```

---

## 🔍 Diagnostic Commands

### Test vault file local

```bash
cd ansible

# Set password
export ANSIBLE_VAULT_PASSWORD="your_password"

# Test view
ansible-vault view group_vars/develop/vault.yml

# Test với playbook
ansible-playbook --syntax-check deploy.yml \
    --vault-password-file <(echo "$ANSIBLE_VAULT_PASSWORD") \
    --extra-vars "env=develop"
```

### Verify vault file format

```bash
# Check if file is encrypted
head -n 1 ansible/group_vars/develop/vault.yml
# Should output: $ANSIBLE_VAULT;1.1;AES256
```

### Test vault_password.sh script

```bash
export ANSIBLE_VAULT_PASSWORD="test_password"
bash ansible/vault_password.sh
# Should output: test_password
```

---

## 📋 Checklist Troubleshooting

- [ ] Jenkins credential `ansible-vault-password` có tồn tại?
- [ ] Password trong Jenkins credential đúng với password dùng khi encrypt?
- [ ] `vault_password.sh` có executable permission? (`chmod +x`)
- [ ] Environment variable `ANSIBLE_VAULT_PASSWORD` có được set?
- [ ] Vault file có đúng format encrypted? (bắt đầu bằng `$ANSIBLE_VAULT`)
- [ ] Test decrypt local có thành công?
- [ ] File path đúng trong `--vault-password-file`?

---

## 🎯 Quick Fix (Thử ngay)

1. **Update Jenkinsfile** với version đã fix (đã update)
2. **Test local decrypt:**
   ```bash
   export ANSIBLE_VAULT_PASSWORD="password_from_jenkins"
   ansible-vault view ansible/group_vars/develop/vault.yml
   ```
3. **Verify Jenkins credential** password đúng
4. **Re-run Jenkins build**

---

## 💡 Best Practices để tránh lỗi

1. **Document vault password** ở nơi an toàn
2. **Test decrypt local** trước khi commit
3. **Use same vault password** cho tất cả environments (đơn giản hơn)
4. **Backup vault files** trước khi rekey
5. **Verify Jenkins credential** sau khi tạo/update

---

Nếu vẫn gặp lỗi, check Jenkins build logs để xem:
- Environment variable có được set không
- Vault password script có chạy không
- Error message chi tiết từ Ansible

