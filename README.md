# Debian
Setup script for Debian 9, 10, and 11

## Summary

- Runs apt update
- Installs base software
- Turns off SSH MotD if installed
- Sets up vim and bash
- Installs guest tools if running a virtual machine

## Usage
### Install curl
```
sudo apt install -y curl
```

### Run the script
```
curl -sL https://raw.githubusercontent.com/Rockz1152/Debian/main/setup.sh | sudo bash
```
