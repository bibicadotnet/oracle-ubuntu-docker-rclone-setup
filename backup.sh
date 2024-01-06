tar -cvf vaultwarden.tar /root/vaultwarden
rclone sync vaultwarden.tar google-drive:_vaultwarden --progress
rm vaultwarden.tar
