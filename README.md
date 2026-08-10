# Bazzite Toolbox Installation Guide

A command-line utility designed to install, configure, and manage Bazzite Toolbox shortcuts within your system environment.

## 🚀 Installation & Setup

Clone the repository, configure executable permissions, and initialize the primary setup script.

```bash
git clone https://github.com/Forbidden-Darkness/Bazzite_Toolbox.git && cd Bazzite_Toolbox/ && chmod +x *.sh && sudo ./start.sh
```

## 🛠️ Configuration Management

### Add System Shortcut
Integrate the Bazzite Toolbox shortcut into the **System & Utilities** directory of your desktop environment's application menu.

```bash
cd Bazzite_Toolbox/ && sudo ./start.sh --install-shortcut && exit
```

### Remove System Shortcut
Remove the application shortcut from the **System & Utilities** menu. 

*Note: This command triggers an automatic system reboot to apply changes and refresh the desktop environment configuration.*

```bash
cd Bazzite_Toolbox/ && sudo ./start.sh --remove-shortcut && systemctl reboot
```
