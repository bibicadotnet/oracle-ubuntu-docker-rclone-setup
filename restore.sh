#!/bin/bash

# cập nhập OS
sudo apt update && sudo apt upgrade -y

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

# Cài đặt docker và docker-compose
curl -sSL https://get.docker.com | sh
sudo usermod -aG docker $(whoami)
sudo systemctl start docker
sudo systemctl enable docker
apt install docker-compose -y

# Cài đặt Rclone
sudo -v ; curl https://rclone.org/install.sh | sudo bash
rclone version

# chỉ dành riêng cho Oracle VPS (không cần cài đặt nếu dùng VPS hãng khác)
sudo wget --no-check-certificate https://raw.githubusercontent.com/bibicadotnet/NeverIdle-Oracle/master/VM.Standard.E2.1.Micro.sh -O /usr/local/bin/bypass_oracle.sh
chmod +x /usr/local/bin/bypass_oracle.sh
nohup /usr/local/bin/bypass_oracle.sh >> ./out 2>&1 <&- &
crontab -l > bypass_oracle
echo "@reboot nohup /usr/local/bin/bypass_oracle.sh >> ./out 2>&1 <&- &" >> bypass_oracle
crontab bypass_oracle

# Copy cấu hình cũ Rclone
sudo wget --no-check-certificate https://you-domain.com/rclone.conf -O /root/.config/rclone/rclone.conf

# Copy backup từ Google Drive xuống
rclone copyto google-drive:_vaultwarden/vaultwarden.tar vaultwarden.tar --progress

# Giải nén file backup
tar -xvf vaultwarden.tar

# Điều chỉnh lại đường dẫn cho phù hợp
mv /root/root/* /root
rm -r /root/root

# Cài đặt lại Vaultwarden
cd vaultwarden
docker-compose up -d --build --remove-orphans --force-recreate

# Cấu hình lại cron
chmod +x /root/vaultwarden/backup.sh
crontab -l > vaultwarden_cron
echo "* * * * * /root/vaultwarden/backup.sh" >> vaultwarden_cron
crontab vaultwarden_cron
