# WoW Classic–Inspired SDDM Theme (v2.2)
Fixes background not loading + button layout for Controls 1.x.

- Uses `Qt.resolvedUrl()` for assets
- Explicit button width/height; right-aligned inside the panel

## Install
```bash
sudo mkdir -p /usr/share/sddm/themes
sudo cp -r /mnt/data/wow-classic-sddm-theme-v2_2 /usr/share/sddm/themes/
sudo mkdir -p /etc/sddm.conf.d
printf "[Theme]\nCurrent=wow-classic-v2_2\n" | sudo tee /etc/sddm.conf.d/theme.conf
```
Replace `assets/background.png` / `assets/logo.png` with your images.
