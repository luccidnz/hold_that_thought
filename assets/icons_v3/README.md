# Icon Update Instructions

To complete the icon update:

1. Unzip the provided icon pack v3 to this folder
2. Replace the following files with the new icons:
   - android/app/src/main/res/mipmap-*/ic_launcher.png
   - android/app/src/main/res/drawable-v26/ic_launcher.xml (if adaptive)
   - web/icons/icon-192.png
   - web/icons/icon-512.png
   - web/favicon.png
   - Update web/manifest.json icon entries if sizes change

3. Rebuild and redeploy

Note: Icon pack v3 should be provided separately and unzipped to this location.