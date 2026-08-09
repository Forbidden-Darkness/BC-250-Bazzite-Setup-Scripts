```bash
git clone https://github.com/Forbidden-Darkness/Bazzite_Toolbox.git && cd Bazzite_Toolbox/ && chmod +x *.sh && sudo ./Start.sh
```



bc250-gfxclk-fix created by Punsh:

Corrects GPU frequency reporting on the AMD BC-250 (Cyan Skillfish / gfx1013) board when all 8 physical CPU cores are enabled, on Bazzite / SteamOS-style image-based (immutable) distros where rebuilding `amdgpu.ko` isn't practical.
