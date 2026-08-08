git clone https://github.com/Forbidden-Darkness/Bazzite_Toolbox.git

cd BC-250-Bazzite-Broken-Toolbox/ && chmod +x *.sh && sudo ./New-Install-Blue-Red-Pill-ACPI-Fix.sh

Example: sudo ./New-Install-Blue-Red-Pill-ACPI-Fix.sh 

bc250-gfxclk-fix created by Punsh:

Corrects GPU frequency reporting on the AMD BC-250 (Cyan Skillfish / gfx1013) board when all 8 physical CPU cores are enabled, on Bazzite / SteamOS-style image-based (immutable) distros where rebuilding `amdgpu.ko` isn't practical.
