#!/bin/bash

# Kiểm tra và thêm hostname vào file /etc/hosts
hostname=$(hostname)
localhost_ip="127.0.0.1"
hosts_file="/etc/hosts"
if grep -q "$hostname" "$hosts_file"; then
    echo "Hostname $hostname đã có trong $hosts_file."
else
    echo "Thêm hostname $hostname vào $hosts_file."
    # Thêm hostname vào file /etc/hosts
    echo "$localhost_ip $hostname" | sudo tee -a "$hosts_file" > /dev/null
    echo "Đã thêm $hostname vào $hosts_file."
fi

# Update và nâng cấp hệ thống
apt-get update -y
DEBIAN_FRONTEND=noninteractive apt-get upgrade -y
DEBIAN_FRONTEND=noninteractive apt-get dist-upgrade -y
apt-get autoremove -y
apt-get clean

# set locale
locale-gen en_US.UTF-8
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# Tắt Firewall
sudo apt remove iptables-persistent -y
sudo ufw disable
sudo iptables -F

# Chỉnh về múi giờ Việt Nam
timedatectl set-timezone Asia/Ho_Chi_Minh

# Cài đặt Chrony, đồng bộ thời gian
apt-get install -y chrony
systemctl start chrony
systemctl enable chrony

# Tạo swap 4GB RAM
sudo fallocate -l 4G /swapfile && sudo chmod 600 /swapfile && sudo mkswap /swapfile && sudo swapon /swapfile && echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
cat <<EOF > /etc/sysctl.d/99-xs-swappiness.conf
vm.swappiness=10
EOF

# Enable TCP BBR congestion control
cat <<EOF > /etc/sysctl.conf
net.core.default_qdisc=fq
net.ipv4.tcp_congestion_control=bbr
EOF

# Cài đặt Docker
curl -fsSL https://get.docker.com | sh
usermod -aG docker $(whoami)
systemctl start docker
systemctl enable docker

# Tối ưu hóa hiệu suất Docker
mkdir -p /etc/docker
cat <<EOF > /etc/docker/daemon.json
{
  "storage-driver": "overlay2",
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  },
  "max-concurrent-downloads": 10,
  "max-concurrent-uploads": 10,
  "dns": ["8.8.8.8", "1.1.1.1"]
}
EOF
systemctl restart docker

# Cài đặt Rclone
sudo -v ; curl https://rclone.org/install.sh | sudo bash
rclone version

# chỉ dành riêng cho Oracle VPS (không cần cài đặt nếu dùng VPS hãng khác)
# sudo wget --no-check-certificate https://raw.githubusercontent.com/bibicadotnet/NeverIdle-Oracle/master/VM.Standard.E2.1.Micro.sh -O /usr/local/bin/bypass_oracle.sh
# chmod +x /usr/local/bin/bypass_oracle.sh
# nohup /usr/local/bin/bypass_oracle.sh >> ./out 2>&1 <&- &
# crontab -l > bypass_oracle
# echo "@reboot nohup /usr/local/bin/bypass_oracle.sh >> ./out 2>&1 <&- &" >> bypass_oracle
# crontab bypass_oracle
