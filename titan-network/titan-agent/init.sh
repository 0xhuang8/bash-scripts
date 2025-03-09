#!/bin/bash

# ==================================================================
# Bắt đầu cài đặt Docker và triển khai Titan-Agent
# ==================================================================

# ==================================================================
# Phần 1: Cài đặt Docker (Ubuntu 22.04)
# ==================================================================

echo "=================================================="
echo "Bắt đầu phần 1: Cài đặt Docker"
echo "=================================================="

# Cập nhật và nâng cấp hệ thống
echo "Bắt đầu cập nhật và nâng cấp hệ thống..."
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get upgrade -y
apt-get autoremove -y
echo "Cập nhật và nâng cấp hệ thống hoàn tất."

# Cài đặt các gói cần thiết để cài đặt Docker
echo "Cài đặt các gói cần thiết cho Docker..."
apt-get install -y apt-transport-https ca-certificates curl software-properties-common gnupg lsb-release
echo "Cài đặt các gói cần thiết cho Docker hoàn tất."

# Thêm khóa GPG chính thức của Docker
echo "Thêm khóa GPG của Docker..."
# Sử dụng --keyring thay vì --dearmor để tránh ghi đè
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --batch --yes --output /usr/share/keyrings/docker-archive-keyring.gpg --dearmor
echo "Khóa GPG của Docker đã được thêm."

# Thiết lập kho lưu trữ Docker
echo "Thiết lập kho lưu trữ Docker..."
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
echo "Kho lưu trữ Docker đã được thiết lập."

# Cài đặt Docker Engine
echo "Cài đặt Docker Engine..."
apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
echo "Docker Engine đã được cài đặt."

# Bắt đầu và kích hoạt Docker
echo "Bắt đầu và kích hoạt Docker..."
systemctl start docker
systemctl enable docker
echo "Docker đã được bắt đầu và kích hoạt."

# Cài đặt Docker Compose (nếu chưa có, sử dụng plugin thì có thể bỏ qua bước này)
echo "Cài đặt Docker Compose..."
# Kiểm tra xem docker-compose đã được cài đặt chưa. Nếu cài rồi thì bỏ qua
if ! command -v docker-compose &> /dev/null
then
  apt-get install -y docker-compose
  echo "Docker Compose đã được cài đặt."
else
  echo "Docker Compose đã được cài đặt, bỏ qua bước này."
fi

echo "=================================================="
echo "Hoàn thành phần 1: Cài đặt Docker"
echo "=================================================="

# ==================================================================
# Phần 2: Triển khai Titan-Agent
# ==================================================================

echo "=================================================="
echo "Bắt đầu phần 2: Triển khai Titan-Agent"
echo "=================================================="

# 1. Tạo thư mục làm việc
mkdir -p /root/titan-agent
echo "Đã tạo thư mục /root/titan-agent"

# 2. Tạo file .env và ghi nội dung
cat <<EOF > /root/titan-agent/.env
KEY=fG2GakpNVkKy
HOOK_ENABLE=false
#HOOK_REGION=cn
#HOOK_INTERFACES=eth0 # 多網卡: eth0,eth1,eth2 不設置會自動抓default gateway
EOF
echo "Đã tạo file /root/titan-agent/.env"

# 3. Tạo file `docker-compose.yml`
cat <<EOF > /root/titan-agent/docker-compose.yml
version: "3.9"
services:
  agent:
    image: aron666/titan-agent2
    privileged: true
    restart: always
    tty: true
    stdin_open: true
    security_opt:
      - apparmor=unconfined
    network_mode: host
    volumes:
      - ./data:/app/data
      - ./data/docker:/var/lib/docker
      - ./.env:/app/agent/.env:ro
      - /etc/docker:/etc/docker:ro
EOF

echo "Đã tạo file /root/titan-agent/docker-compose.yml"

# 4. Tạo thư mục data (cần thiết cho volume)
mkdir -p /root/titan-agent/data/docker
mkdir -p /root/titan-agent/data
echo "Đã tạo thư mục /root/titan-agent/data và /root/titan-agent/data/docker"

# 5. Triển khai container bằng docker-compose
cd /root/titan-agent
echo "Chuyển đến thư mục /root/titan-agent"

if command -v docker-compose &> /dev/null
then
  docker-compose up -d
  echo "Đã triển khai container bằng docker-compose"
elif command -v docker &> /dev/null
then
  docker compose up -d
  echo "Đã triển khai container bằng docker compose"

else
  echo "Lỗi: docker-compose hoặc docker compose không được tìm thấy.  Vui lòng cài đặt trước khi chạy script này."
  exit 1
fi

echo "=================================================="
echo "Hoàn thành phần 2: Triển khai Titan-Agent"
echo "=================================================="

echo "=================================================="
echo "Hoàn tất toàn bộ quá trình cài đặt và triển khai!"
echo "=================================================="
