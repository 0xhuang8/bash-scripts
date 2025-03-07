#!/bin/bash
# setup-titan.sh - Script cài đặt nhanh Titan Agent với KEY tùy chỉnh
# Sử dụng: ./setup-titan.sh [KEY]
# Ví dụ: ./setup-titan.sh my-custom-key

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

# Lấy KEY từ tham số hoặc sử dụng mặc định
AGENT_KEY=${1:-"fG2GakpNVkKy"}

echo "=== Bắt đầu cài đặt Titan Agent ==="

# Tạo và di chuyển đến thư mục dự án
mkdir -p ~/titan-agent
cd ~/titan-agent

echo "1. Tạo cấu trúc thư mục tại $(pwd)..."
mkdir -p app/agent data/agent

echo "2. Tạo file .env với KEY..."
echo "KEY=$AGENT_KEY" > app/agent/.env
echo "- Đã cấu hình KEY: $AGENT_KEY"

echo "3. Tạo file docker-compose.yml..."
cat > docker-compose.yml << 'EOF'
version: "3.9"
services:
  agent:
    image: laodauhgc/titan-agent:latest
    container_name: titan-agent
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
      - ./app/agent/.env:/app/agent/.env:ro
      - /etc/docker:/etc/docker:ro
      - /var/run/docker.sock:/var/run/docker.sock
    environment:
      - TARGETARCH=amd64
      - OS=linux
      - WORKSPACE=/app/data/agent
      - AGENT_PATH=/app/agent
      - MULTIPASS_PATH=/app/multipass
      - SERVER_URL=https://test4-api.titannet.io
      - DATA_DIR=/app/data
      - LOG_FILE=/app/data/agent/agent.log
      - HOOKS_DIR=/app/hooks
EOF

echo "4. Khởi động container..."
docker-compose up -d

echo "=== Cài đặt hoàn tất! ==="
echo "- Thư mục cài đặt: $(pwd)"
echo "- KEY được cấu hình: $AGENT_KEY"
echo "- Kiểm tra logs với lệnh: cd ~/titan-agent && docker-compose logs -f"
echo "- Trạng thái container:"
docker ps | grep titan-agent

echo ""
echo "Quản lý Titan Agent:"
echo "- Khởi động: cd ~/titan-agent && docker-compose up -d"
echo "- Dừng: cd ~/titan-agent && docker-compose down"
echo "- Khởi động lại: cd ~/titan-agent && docker-compose restart"
