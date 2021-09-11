#!/bin/bash

# OS Check
if [[ `cat /etc/debian_version 2>/dev/null | grep -E '11.|10.|9.' | wc -l` == 1 ]]; then
    echo ''
    echo 'Provisioning Debian'
    echo ''
else
    echo 'This script is designed to only run on Debian 9, 10, or 11'
    exit 1
fi

# Check for root, otherwise re-run
[ `whoami` = root ] || { sudo "$0" "$@"; exit $?; }

# Apt update and upgrade
echo 'Running apt-update'
apt-get -q update > /dev/null
echo 'Running apt-upgrade'
apt-get -q -y dist-upgrade > /dev/null

# Software to install
echo 'Installing software'
declare -a packages=('curl' 'nano' 'vim' 'htop' 'ncdu' 'wget' 'zip' 'unzip' 'p7zip-full' 'screen' 'less' 'man-db' 'neofetch')

# Check for VMware
if [[ `dmidecode -t system | grep Manufacturer | awk '{sub(/Manufacturer:/,"");print}' | xargs` == "VMware, Inc." ]]; then
    packages=(${packages[@]} "open-vm-tools")
fi
# Check for QEMU
if [[ `dmidecode -t system | grep Manufacturer | awk '{sub(/Manufacturer:/,"");print}' | xargs` == "QEMU" ]]; then
    packages=(${packages[@]} "qemu-guest-agent")
fi

# Install software
for i in "${packages[@]}"
do
    echo '-'$i
    if [[ `dpkg-query -W -f='${Status}' $i 2>/dev/null | grep -c "ok installed"` == 0 ]]; then
        apt-get -q -y install $i > /dev/null 2>/dev/null
        # Verify install
        if [[ `dpkg-query -W -f='${Status}' $i 2>/dev/null | grep -c "ok installed"` == 0 ]]; then
            echo '!!!' $i 'failed to install'
        fi
    fi
done

# Disable motd on ssh login
if [ -f /etc/pam.d/sshd ]; then
echo 'Turning off SSH motd'
sudo sed -i 's@.*session    optional     pam_motd.so  motd=/run/motd.dynamic@#session    optional     pam_motd.so  motd=/run/motd.dynamic@' /etc/pam.d/sshd
sudo sed -i 's@.*session    optional     pam_motd.so noupdate@#session    optional     pam_motd.so noupdate@' /etc/pam.d/sshd
fi

# Configure vim
echo 'Configuring Vim'

if [[ `cat /etc/debian_version 2>/dev/null | grep 11.` ]]; then
    echo "source /usr/share/vim/vim82/defaults.vim" > /root/.vimrc
elif [[ `cat /etc/debian_version 2>/dev/null | grep 10.` ]]; then
    echo "source /usr/share/vim/vim81/defaults.vim" > /root/.vimrc
elif [[ `cat /etc/debian_version 2>/dev/null | grep 9.` ]]; then
    echo "source /usr/share/vim/vim80/defaults.vim" > /root/.vimrc
fi

cat >> /root/.vimrc << EOF
colorscheme desert
set nowrap

let skip_defaults_vim = 1

if has('mouse')
 set mouse=r
endif
EOF

# Configure bash
echo 'Configuring Bash'
\cp /etc/skel/.bashrc /root/.bashrc
cat >> /root/.bashrc << EOF

alias reboot='/sbin/reboot'
alias shutdown='/sbin/shutdown'
alias ll='ls -l'
alias la='ls -lA'
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'
alias grep='grep --color=auto'
EOF

# Configure bash input
cat > /root/.inputrc << EOF
\$include /etc/inputrc
set enable-bracketed-paste Off
EOF

# Copy dotfiles into home directories
for d in `find /home/* -maxdepth 0 -type d`
do
    \cp /root/.bashrc $d
    \cp /root/.vimrc $d
    \cp /root/.inputrc $d
done

# Reload bash for sudo user
echo 'Reloading Bash'
echo ''
# sudo -u $SUDO_USER sh -c "exec bash"
