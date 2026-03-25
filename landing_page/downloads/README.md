# Instructions for App Downloads

To enable downloads on your landing page, follow these steps:

## 1. Local Hosting (Simple)
Create a `downloads` folder inside the `landing_page` directory and place your files there:
- `landing_page/downloads/ChiTieuPlus_Setup.exe`
- `landing_page/downloads/ChiTieuPlus.dmg`

## 2. Remote Hosting (Recommended)
If you publish your app to an App Store or host files on cloud storage (like Firebase Storage or GitHub Releases):
1. Get the public URL for the file.
2. Open `landing_page/script.js`.
3. Update the `DOWNLOAD_URLS` object (lines 9-13) with your real links.

**Current Links Map in `script.js`:**
```javascript
const DOWNLOAD_URLS = {
    'Windows': 'downloads/ChiTieuPlus_Setup.exe',
    'macOS': 'downloads/ChiTieuPlus.dmg',
    'Linux': 'downloads/ChiTieuPlus.AppImage',
    'Android': 'https://play.google.com/store/apps/details?id=com.chitieu_plus',
    'iOS': 'https://apps.apple.com/app/chitieuplus',
};
```
