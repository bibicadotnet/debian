#!/usr/bin/env bash

# Set the local
export LANG="en_US.UTF-8"
export LC_ALL="C"

echo -e "nameserver 8.8.8.8\nnameserver 1.1.1.1" > /etc/resolv.conf

## Force APT to use IPv4
echo -e "Acquire::ForceIPv4 \"true\";\\n" > /etc/apt/apt.conf.d/99force-ipv4

## Set Timezone to UTC and enable NTP
timedatectl set-timezone Asia/Ho_Chi_Minh
cat <<'EOF' > /etc/systemd/timesyncd.conf
[Time]
NTP=0.pool.ntp.org 1.pool.ntp.org 2.pool.ntp.org 3.pool.ntp.org
FallbackNTP=0.debian.pool.ntp.org 1.debian.pool.ntp.org 2.debian.pool.ntp.org 3.debian.pool.ntp.org
RootDistanceMaxSec=5
PollIntervalMinSec=32
PollIntervalMaxSec=2048
EOF
service systemd-timesyncd start
timedatectl set-ntp true

## Increase max user watches
# BUG FIX : No space left on device
echo "fs.inotify.max_user_instances=524288" >> /etc/sysctl.conf
echo "fs.inotify.max_user_watches=524288" >> /etc/sysctl.conf
echo "fs.inotify.max_queued_events=524288" >> /etc/sysctl.conf
## Set max map count, required for elasticsearch
echo "vm.max_map_count=262144" >> /etc/sysctl.conf
## Apply sysctl.conf
sysctl -p /etc/sysctl.conf

## Increase max FD limit / ulimit
cat <<'EOF' >> /etc/security/limits.conf
# Increase max FD limit / ulimit
* soft     nproc          256000
* hard     nproc          256000
* soft     nofile         256000
* hard     nofile         256000
root soft     nproc          256000
root hard     nproc          256000
root soft     nofile         256000
root hard     nofile         256000
EOF

## Set systemd ulimits
echo "DefaultLimitNOFILE=256000" >> /etc/systemd/system.conf
echo "DefaultLimitNOFILE=256000" >> /etc/systemd/user.conf
echo 'session required pam_limits.so' | tee -a /etc/pam.d/common-session-noninteractive
echo 'session required pam_limits.so' | tee -a /etc/pam.d/common-session
echo 'session required pam_limits.so' | tee -a /etc/pam.d/runuser-l

## Set ulimit for the shell user
cd ~ && echo "ulimit -n 256000" >> .bashrc ; echo "ulimit -n 256000" >> .profile

## Increase kernel max Key limit
cat <<EOF > /etc/sysctl.d/99-xs-maxkeys.conf
# Increase kernel max Key limit
kernel.keys.root_maxkeys=1000000
kernel.keys.maxkeys=1000000
EOF

## Enable TCP BBR congestion control
cat <<EOF > /etc/sysctl.d/99-xs-kernel-bbr.conf
# TCP BBR congestion control
net.core.default_qdisc=fq
net.ipv4.tcp_congestion_control=bbr
EOF

## Memory Optimising
cat <<EOF > /etc/sysctl.d/99-xs-memory.conf
# Memory Optimising
vm.min_free_kbytes=65536
vm.nr_hugepages=72
# (Redis/MongoDB)
vm.overcommit_memory = 1
EOF

## TCP fastopen
cat <<EOF > /etc/sysctl.d/99-xs-tcp-fastopen.conf
# TCP fastopen
net.ipv4.tcp_fastopen=3
EOF

## FS Optimising
cat <<EOF > /etc/sysctl.d/99-xs-tcp-fastopen.conf
# FS Optimising
fs.nr_open=12000000
fs.file-max=9000000
EOF

## Net optimising
cat <<EOF > /etc/sysctl.d/99-xs-net.conf
net.core.netdev_max_backlog=8192
net.core.optmem_max=8192
net.core.rmem_max=16777216
net.core.somaxconn=8151
net.core.wmem_max=16777216
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.all.log_martians = 1
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.all.secure_redirects = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv4.conf.default.accept_source_route = 0
net.ipv4.conf.default.log_martians = 1
net.ipv4.conf.default.rp_filter = 1
net.ipv4.conf.default.secure_redirects = 0
net.ipv4.conf.default.send_redirects = 0
net.ipv4.icmp_echo_ignore_broadcasts = 1
net.ipv4.icmp_ignore_bogus_error_responses = 1
net.ipv4.ip_local_port_range=1024 65535
net.ipv4.tcp_base_mss = 1024
net.ipv4.tcp_challenge_ack_limit = 999999999
net.ipv4.tcp_fin_timeout=10
net.ipv4.tcp_keepalive_intvl=30
net.ipv4.tcp_keepalive_probes=3
net.ipv4.tcp_keepalive_time=240
net.ipv4.tcp_limit_output_bytes=65536
net.ipv4.tcp_max_syn_backlog=8192
net.ipv4.tcp_max_tw_buckets = 1440000
net.ipv4.tcp_mtu_probing = 1
net.ipv4.tcp_rfc1337=1
net.ipv4.tcp_rmem=8192 87380 16777216
net.ipv4.tcp_sack=1
net.ipv4.tcp_slow_start_after_idle=0
net.ipv4.tcp_syn_retries=3
net.ipv4.tcp_synack_retries = 2
net.ipv4.tcp_tw_recycle = 0
net.ipv4.tcp_tw_reuse = 0
net.ipv4.tcp_wmem=8192 65536 16777216
net.netfilter.nf_conntrack_generic_timeout = 60
net.netfilter.nf_conntrack_helper=0
net.netfilter.nf_conntrack_max = 524288
net.netfilter.nf_conntrack_tcp_timeout_established = 28800
net.unix.max_dgram_qlen = 4096
EOF

## Script Finish
echo -e '\033[1;33m Finished....please restart the system \033[0m'
