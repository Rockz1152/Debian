#!/bin/bash

# Setup Script for Debian 9, 10, and 11
# https://github.com/Rockz1152/Debian

function checkOS() {
    echo "Checking OS"
    if [[ -e /etc/debian_version ]]; then
        source /etc/os-release
        if [[ ${ID} == "debian" || ${ID} == "raspbian" ]]; then
            if [[ ${VERSION_ID} -lt 9 ]]; then
                echo "Your version of Debian (${VERSION_ID}) is not supported. Please use Debian 9 Stretch or later"
                exit 1
            fi
        fi
    else
        echo "Looks like you aren't running this installer on a supported Debian install"
        exit 1
    fi
}

function checkRoot() {
    if [ "${EUID}" -ne 0 ]; then
        echo "You need to run this script as root"
        exit 1
    fi
}

function installSoftware() {
    # Apt update and upgrade
    echo 'Running apt-update'
    apt-get -q update > /dev/null
    echo 'Running apt-upgrade'
    apt-get -q -y dist-upgrade > /dev/null

    # Software to install
    echo 'Installing software'
    declare -a packages=('curl' 'nano' 'vim' 'htop' 'ncdu' 'wget' 'zip' 'unzip' 'p7zip-full' 'screen' 'less' 'man-db' 'neofetch')

    # Check for VMware
    if [ "$(systemd-detect-virt)" == "vmware" ]; then
        packages=(${packages[@]} "open-vm-tools")
    fi

    # Check for QEMU
    if [ "$(systemd-detect-virt)" == "qemu" ]; then
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
}

function sshMotd() {
    if [ -f /etc/pam.d/sshd ]; then
        echo 'Turning off SSH motd'
        sudo sed -i 's@.*session    optional     pam_motd.so  motd=/run/motd.dynamic@#session    optional     pam_motd.so  motd=/run/motd.dynamic@' /etc/pam.d/sshd
        sudo sed -i 's@.*session    optional     pam_motd.so noupdate@#session    optional     pam_motd.so noupdate@' /etc/pam.d/sshd
    fi
}

function configVIM() {
    echo 'Configuring Vim'
cat > /etc/vim/vimrc.local << EOF
source \$VIMRUNTIME/defaults.vim
let skip_defaults_vim = 1

colorscheme desert
set nowrap

if has('mouse')
 set mouse=r
endif
EOF
}

function configBash() {
    echo 'Configuring Bash'
    # \cp /etc/skel/.bashrc /root/.bashrc
cat > /etc/profile.d/bashrc.sh << EOF
#!/bin/sh
alias reboot='/sbin/reboot'
alias shutdown='/sbin/shutdown'
alias ll='ls -l'
alias la='ls -lA'
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'
alias grep='grep --color=auto'
EOF
# Configure bash input, Debian 11+ only
    if [[ ${VERSION_ID} -ge 11 ]]; then
cat > /root/.inputrc << EOF
\$include /etc/inputrc
set enable-bracketed-paste Off
EOF
        for d in /home/* ;
        do
            \cp /root/.inputrc $d
        done
    fi
}

function reloadBash() {
    echo 'Reloading Bash'
    echo ''
    exec "$BASH" --login
}

checkOS
checkRoot
installSoftware
sshMotd
configVIM
configBash
reloadBash
