# Hướng dẫn kiểm tra và cài đặt Ansible trên Jenkins Server

## Kiểm tra Ansible đã được cài đặt chưa

### Cách 1: SSH vào Jenkins server/agent và chạy:

```bash
# Kiểm tra ansible-playbook có trong PATH không
ansible-playbook --version

# Hoặc kiểm tra vị trí cài đặt
which ansible-playbook
command -v ansible-playbook
```

### Cách 2: Chạy script kiểm tra

```bash
# Trên Jenkins server/agent (Linux/macOS)
bash check_ansible.sh

# Hoặc chạy trực tiếp các lệnh kiểm tra
command -v ansible-playbook &> /dev/null && echo "Found" || echo "Not found"
```

## Cài đặt Ansible

### Trên Linux (Ubuntu/Debian):

```bash
# Cập nhật package list
sudo apt update

# Cài đặt Ansible
sudo apt install ansible -y

# Kiểm tra
ansible-playbook --version
```

### Trên Linux (CentOS/RHEL):

```bash
# Cài đặt EPEL repository (nếu chưa có)
sudo yum install epel-release -y

# Cài đặt Ansible
sudo yum install ansible -y

# Kiểm tra
ansible-playbook --version
```

### Sử dụng pip3 (khuyến nghị - cho mọi hệ điều hành):

```bash
# Cài đặt pip3 nếu chưa có
sudo apt install python3-pip -y  # Ubuntu/Debian
# hoặc
sudo yum install python3-pip -y  # CentOS/RHEL

# Cài đặt Ansible
pip3 install ansible

# Nếu cần cài đặt system-wide
sudo pip3 install ansible

# Kiểm tra
ansible-playbook --version
```

### Trên macOS:

```bash
# Sử dụng Homebrew
brew install ansible

# Hoặc sử dụng pip3
pip3 install ansible

# Kiểm tra
ansible-playbook --version
```

## Kiểm tra PATH

Đảm bảo thư mục chứa ansible-playbook có trong PATH:

```bash
# Xem PATH hiện tại
echo $PATH

# Kiểm tra các vị trí thường gặp
ls -la /usr/local/bin/ansible-playbook
ls -la /usr/bin/ansible-playbook
ls -la ~/.local/bin/ansible-playbook

# Nếu cài bằng pip3 user mode, thêm vào PATH
export PATH="$HOME/.local/bin:$PATH"
```

## Thêm vào PATH vĩnh viễn

### Cho user hiện tại:

```bash
# Thêm vào ~/.bashrc hoặc ~/.bash_profile
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

### Cho toàn hệ thống:

```bash
# Thêm vào /etc/environment hoặc /etc/profile
sudo echo 'PATH="/usr/local/bin:/usr/bin:$HOME/.local/bin:$PATH"' >> /etc/environment
```

## Kiểm tra trên Jenkins Pipeline

Pipeline sẽ tự động kiểm tra và báo lỗi nếu không tìm thấy. Bạn có thể xem log trong Jenkins console output để biết:

- `Found ansible-playbook as command in PATH` - Đã tìm thấy
- `Found ansible-playbook at: /path/to/ansible-playbook` - Tìm thấy tại path cụ thể
- `ansible-playbook not found` - Chưa cài đặt

## Troubleshooting

### Lỗi: "ansible-playbook not found"

1. Kiểm tra Ansible đã được cài đặt:
   ```bash
   pip3 list | grep ansible
   ```

2. Kiểm tra vị trí cài đặt:
   ```bash
   pip3 show ansible | grep Location
   ```

3. Tìm file ansible-playbook:
   ```bash
   find /usr -name ansible-playbook 2>/dev/null
   find ~ -name ansible-playbook 2>/dev/null
   ```

4. Nếu tìm thấy nhưng không trong PATH, thêm vào PATH hoặc tạo symlink:
   ```bash
   # Tìm thấy tại /path/to/ansible-playbook
   sudo ln -s /path/to/ansible-playbook /usr/local/bin/ansible-playbook
   ```

### Lỗi: Permission denied

```bash
# Đảm bảo file có quyền thực thi
chmod +x $(which ansible-playbook)

# Hoặc nếu cài bằng pip user mode
chmod +x ~/.local/bin/ansible-playbook
```

## Lưu ý

- Nếu Jenkins chạy như một service, có thể cần restart Jenkins sau khi cài đặt Ansible
- Đảm bảo user chạy Jenkins có quyền truy cập ansible-playbook
- Nếu dùng Jenkins agent, cần cài đặt Ansible trên agent đó, không phải trên master

## Vấn đề thường gặp: "ansible-playbook found khi chạy script nhưng không tìm thấy trong pipeline"

### Nguyên nhân:

1. **User khác nhau**: Jenkins thường chạy với user `jenkins` (hoặc user khác), không phải user bạn đang SSH vào
2. **PATH khác nhau**: User `jenkins` có PATH khác với user thường
3. **Ansible cài cho user cụ thể**: Nếu cài bằng `pip3 install --user`, chỉ user đó mới có quyền truy cập

### Giải pháp:

#### 1. Kiểm tra user chạy Jenkins:

```bash
# Xem user nào chạy Jenkins
ps aux | grep jenkins

# Hoặc
sudo systemctl status jenkins | grep "Main PID"
```

#### 2. Cài Ansible cho user Jenkins:

```bash
# Chuyển sang user jenkins
sudo su - jenkins

# Cài Ansible
pip3 install --user ansible

# Thêm vào PATH
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc

# Kiểm tra
ansible-playbook --version
```

#### 3. Hoặc cài system-wide (cho tất cả users):

```bash
# Sử dụng pip3 system-wide
sudo pip3 install ansible

# Hoặc dùng package manager
sudo apt install ansible  # Ubuntu/Debian
sudo yum install ansible  # CentOS/RHEL
```

#### 4. Kiểm tra PATH của Jenkins user:

```bash
# SSH vào server với user jenkins
sudo su - jenkins

# Xem PATH
echo $PATH

# Kiểm tra ansible-playbook
which ansible-playbook
command -v ansible-playbook
```

#### 5. Cấu hình PATH trong Jenkins (nếu cần):

- Vào Jenkins → Manage Jenkins → Configure System
- Tìm phần "Global properties" → "Environment variables"
- Thêm biến PATH với giá trị: `/usr/local/bin:/usr/bin:/home/jenkins/.local/bin:$PATH`

### Debug trong Pipeline:

Pipeline đã được cập nhật để:
- Tự động tìm ansible-playbook trong PATH
- Hiển thị debug info (user, PATH, working directory)
- Fallback sang tìm trong PATH nếu path cụ thể không hợp lệ
- Thử nhiều phương pháp để tìm ansible-playbook

Xem log trong Jenkins console output để biết:
- User nào đang chạy pipeline
- PATH hiện tại là gì
- ansible-playbook được tìm thấy ở đâu

