# Hướng dẫn Deploy Project lên AWS EC2

## Yêu cầu trước khi deploy

### 1. Chuẩn bị EC2 Instance

- Đã tạo EC2 instance trên AWS
- Instance đã được cấu hình với:
  - Ubuntu OS (hoặc Linux tương thích)
  - Security Group cho phép SSH (port 22) và HTTP/HTTPS (port 80/443)
  - Elastic IP hoặc Public IP đã được gán

### 2. Cấu hình SSH Key

1. **Tải SSH Private Key từ AWS:**
   - Tải file `.pem` key từ AWS Console
   - Đặt vào thư mục `~/.ssh/` với tên `ec2-key.pem`
   - Set quyền: `chmod 400 ~/.ssh/ec2-key.pem`

2. **Hoặc cập nhật đường dẫn key trong inventory:**
   - Mở file `ansible/inventory`
   - Cập nhật `ansible_ssh_private_key_file` với đường dẫn đến key file của bạn

### 3. Cấu hình Jenkins

1. **Cài đặt Ansible trên Jenkins server:**
   ```bash
   sudo apt-get update
   sudo apt-get install -y ansible
   ```

2. **Cài đặt các dependencies cần thiết:**
   ```bash
   sudo apt-get install -y python3-pip
   pip3 install boto3  # Nếu cần AWS integration
   ```

3. **Cấu hình Jenkins Credentials:**
   - Tạo credential với ID: `ansible-vault-password`
   - Loại: Secret text
   - Nhập password để decrypt Ansible Vault

### 4. Cấu hình Ansible Vault

1. **Tạo/Update vault với thông tin nhạy cảm:**
   ```bash
   cd ansible/group_vars/develop
   ansible-vault edit vault.yml
   ```

2. **Các biến cần thiết trong vault.yml:**
   ```yaml
   db_name: your_database_name
   db_user: your_database_user
   db_password: your_database_password
   app_key: your_app_key  # Hoặc để trống để tự generate
   mail_username: your_mail_username
   mail_password: your_mail_password
   # ... các biến nhạy cảm khác
   ```

### 5. Chuẩn bị EC2 Server

Trên EC2 instance, cần cài đặt:

1. **Web Server (Apache hoặc Nginx):**
   ```bash
   sudo apt-get update
   sudo apt-get install -y apache2
   sudo apt-get install -y php php-mysql php-mbstring php-xml php-curl php-zip
   ```

2. **Database (MySQL/MariaDB):**
   ```bash
   sudo apt-get install -y mysql-server
   ```

3. **Composer:**
   ```bash
   curl -sS https://getcomposer.org/installer | php
   sudo mv composer.phar /usr/local/bin/composer
   ```

4. **Cấu hình Apache:**
   - Tạo VirtualHost trỏ đến `/var/www/laravel-app/public`
   - Enable mod_rewrite: `sudo a2enmod rewrite`
   - Restart Apache: `sudo systemctl restart apache2`

## Các bước Deploy

### Deploy qua Jenkins

1. **Mở Jenkins Pipeline:**
   - Vào Jenkins dashboard
   - Chọn project của bạn
   - Click "Build with Parameters"
   - Chọn `DEPLOY_ENV = develop`

2. **Jenkins sẽ tự động:**
   - Checkout code
   - Install dependencies
   - Run tests
   - Tạo deployment package
   - Deploy lên EC2 qua Ansible

### Deploy thủ công với Ansible

Nếu muốn deploy trực tiếp từ máy local:

```bash
# 1. Export vault password
export ANSIBLE_VAULT_PASSWORD="your-vault-password"

# 2. Chạy playbook
cd ansible
ansible-playbook -i inventory deploy.yml \
  --vault-password-file vault_password.sh \
  --extra-vars "env=develop deploy_package=laravel-app.zip deploy_package_path=/path/to/package.zip" \
  --limit develop
```

## Cấu trúc Files

```
ansible/
├── ansible.cfg              # Cấu hình Ansible
├── inventory                # Danh sách servers
├── deploy.yml               # Playbook chính
├── vault_password.sh        # Script lấy vault password
├── group_vars/
│   └── develop/
│       ├── vars.yml         # Biến không nhạy cảm
│       └── vault.yml         # Biến nhạy cảm (encrypted)
└── roles/
    └── laravel_deploy/
        ├── tasks/main.yml   # Các task deploy
        ├── defaults/main.yml # Default variables
        └── templates/env.j2   # Template .env file
```

## Troubleshooting

### Lỗi SSH Connection

1. **Kiểm tra Security Group:**
   - Đảm bảo port 22 đã được mở trong Security Group

2. **Kiểm tra SSH Key:**
   ```bash
   ssh -i ~/.ssh/ec2-key.pem ubuntu@ec2-13-229-150-173.ap-southeast-1.compute.amazonaws.com
   ```

3. **Kiểm tra inventory:**
   - Đảm bảo `ansible_host` và `ansible_user` đúng
   - Kiểm tra `ansible_ssh_private_key_file` trỏ đúng file key

### Lỗi Permission

1. **Trên EC2 server:**
   ```bash
   sudo chown -R www-data:www-data /var/www/laravel-app
   sudo chmod -R 755 /var/www/laravel-app
   sudo chmod -R 775 /var/www/laravel-app/storage
   sudo chmod -R 775 /var/www/laravel-app/bootstrap/cache
   ```

### Lỗi Database Connection

1. **Kiểm tra MySQL:**
   ```bash
   sudo mysql -u root -p
   CREATE DATABASE your_database_name;
   CREATE USER 'your_user'@'localhost' IDENTIFIED BY 'your_password';
   GRANT ALL PRIVILEGES ON your_database_name.* TO 'your_user'@'localhost';
   FLUSH PRIVILEGES;
   ```

2. **Kiểm tra vault.yml:**
   - Đảm bảo thông tin database đã được cấu hình đúng trong vault.yml

## Cập nhật thông tin EC2

Nếu bạn có EC2 instance mới hoặc thay đổi thông tin:

1. **Cập nhật inventory:**
   ```ini
   [develop]
   deve-server ansible_host=YOUR_EC2_PUBLIC_IP_OR_DNS ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/your-key.pem
   ```

2. **Cập nhật app_url trong vars.yml:**
   ```yaml
   app_url: http://YOUR_EC2_PUBLIC_IP_OR_DNS
   ```

## Security Best Practices

1. **Không commit vault.yml vào git:**
   - Đảm bảo `.gitignore` đã ignore file vault.yml
   - Hoặc chỉ commit encrypted version

2. **Sử dụng Ansible Vault:**
   - Luôn encrypt các thông tin nhạy cảm
   - Không hardcode passwords trong code

3. **EC2 Security:**
   - Sử dụng Security Groups để giới hạn access
   - Chỉ mở ports cần thiết
   - Sử dụng IAM roles thay vì access keys khi có thể

## Rollback

Nếu deployment thất bại, Ansible sẽ tự động rollback về version trước đó. Backups được lưu tại:
```
/var/www/laravel-app-backups/
```

Để rollback thủ công:
```bash
# SSH vào EC2
ssh -i ~/.ssh/ec2-key.pem ubuntu@your-ec2-ip

# Xem danh sách backups
ls -la /var/www/laravel-app-backups/

# Restore từ backup
sudo cp -a /var/www/laravel-app-backups/backup_YYYYMMDD_HHMMSS/* /var/www/laravel-app/
sudo chown -R www-data:www-data /var/www/laravel-app
sudo systemctl restart apache2
```

