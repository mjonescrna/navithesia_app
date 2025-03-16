# NaviThesia App Icon Setup Instructions

## Icon Files Created
I've set up the XML structure for an adaptive icon. This ensures your app icon will display correctly at the proper size on modern Android devices.

## Manual Steps Required

Since I can't directly manipulate image files, you'll need to take these steps to complete your app icon:

### 1. Create Foreground Images

You'll need to create the foreground icon file at the following sizes:

- `android/app/src/main/res/mipmap-mdpi/ic_launcher_foreground.png` - 108×108px
- `android/app/src/main/res/mipmap-hdpi/ic_launcher_foreground.png` - 162×162px
- `android/app/src/main/res/mipmap-xhdpi/ic_launcher_foreground.png` - 216×216px
- `android/app/src/main/res/mipmap-xxhdpi/ic_launcher_foreground.png` - 324×324px
- `android/app/src/main/res/mipmap-xxxhdpi/ic_launcher_foreground.png` - 432×432px

### 2. Optimize Your Logo for Adaptive Icons

- The actual design should only occupy the center 72% of the image
- Keep the outer edges transparent (this is the "safe zone" for different shaped launchers)
- The "NT" portion of your logo should be clearly visible and take up sufficient space

### 3. Create Regular Icons

You should also replace the standard launcher icons (for older devices):

- `android/app/src/main/res/mipmap-mdpi/ic_launcher.png` - 48×48px
- `android/app/src/main/res/mipmap-hdpi/ic_launcher.png` - 72×72px
- `android/app/src/main/res/mipmap-xhdpi/ic_launcher.png` - 96×96px
- `android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png` - 144×144px
- `android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png` - 192×192px

### Tools to Help

You can use the Android Studio Asset Studio to generate these automatically:
1. Open your project in Android Studio
2. Right-click on the `res` folder 
3. Select "New > Image Asset"
4. Choose "Launcher Icons (Adaptive and Legacy)"
5. Import your logo as the foreground layer
6. Choose white for the background
7. Generate the icons

Alternatively, you can use online tools like:
- [Adaptive Icon Generator](https://adaptiveicon.glitch.me/)
- [App Icon Generator](https://appicon.co/)
- [MakeAppIcon](https://makeappicon.com/)

By following these steps, your app icon will display at the proper size on your Pixel 8a and all other Android devices. 