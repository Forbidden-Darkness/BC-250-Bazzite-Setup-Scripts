### Install Bazzite Toolbox in your home folder
```bash
git clone https://github.com/Forbidden-Darkness/Bazzite_Toolbox.git && cd Bazzite_Toolbox/ && chmod +x *.sh && sudo ./start.sh
```

### Create Bazzite Toolbox shortcut within your start menu under SYSTEM & UTILITIES
```bash
cd Bazzite_Toolbox/ && sudo ./start.sh --install-shortcut && exit
```

### Remove Bazzite Toolbox from your start menu under SYSTEM & UTILITIES
```bash
cd Bazzite_Toolbox/ && sudo ./start.sh --remove-shortcut && systemctl reboot
```
