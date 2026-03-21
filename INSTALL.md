# Installing PandaAutomator on Your iPhone

This guide walks you through sideloading the PandaAutomator app onto your iPhone using Xcode. No prior Xcode experience is required.

## Prerequisites

Before you begin, make sure you have:

- **A Mac** running macOS 13 Ventura or later
- **Xcode 15 or later** -- free from the Mac App Store. Note: Xcode is a large download (several gigabytes), so plan accordingly.
- **An Apple ID** -- a free account works. However, with a free account the app expires after 7 days and must be re-installed from Xcode. A paid Apple Developer account ($99/year) removes this limitation.
- **An iPhone** with a Lightning or USB-C cable that supports data transfer (not a charge-only cable)
- **This repository** cloned or downloaded to your Mac

## Step-by-Step Installation

Follow every step in order. Do not skip ahead.

1. **Open the Xcode project.** Double-click `PandaAutomator/PandaAutomator.xcodeproj` in Finder, or open Xcode and use **File > Open** to navigate to it.

2. **Select the PandaAutomator target.** In the left sidebar (the Project Navigator), click **PandaAutomator** under the **Targets** heading. Make sure you click the target, not the top-level project icon above it.

3. **Open the Signing & Capabilities tab.** With the target selected, look at the top of the editor area. Click the **Signing & Capabilities** tab.

4. **Enable automatic signing.** Check the **Automatically manage signing** checkbox. This lets Xcode handle provisioning profiles and certificates for you.

5. **Choose your Team.** In the **Team** dropdown, change from `[None]` to your Apple ID account. If your Apple ID does not appear in the list, continue to step 6.

6. **Sign in with your Apple ID.** If Xcode prompts you to sign in, enter your Apple ID credentials. Xcode will create a free development certificate automatically. If you already see your account in step 5, you can move on.

7. **Connect your iPhone.** Plug your iPhone into your Mac with a cable. If your iPhone shows a **"Trust This Computer?"** dialog, tap **Trust** and enter your passcode.

8. **Select your iPhone as the run destination.** In the Xcode toolbar at the top of the window, click the device/simulator selector. It may currently say "Any iOS Device" or show a simulator name. Choose your iPhone from the list.

9. **Click Run.** Click the **Run** button (the play triangle in the upper-left corner of Xcode) or press **Cmd+R**. Xcode will compile the app and attempt to install it on your iPhone.

10. **Trust the developer on your iPhone.** The first install may fail with an **"Untrusted Developer"** error. This is normal. On your iPhone, go to **Settings > General > VPN & Device Management**. Find the entry under "Developer App" that corresponds to your Apple ID, and tap **Trust**.

11. **Run again from Xcode.** Go back to Xcode and click **Run** (or press **Cmd+R**) one more time. The app should now install and launch without the trust error.

12. **Wait for the build and install to complete.** The app will launch automatically on your iPhone once the install finishes. You should see the PandaAutomator interface appear on screen.

13. **Disconnect your iPhone.** You can now unplug the cable. The app is installed and ready to use.

## Troubleshooting

### "Untrusted Developer" Error

This happens on the first install with a new development certificate. On your iPhone, go to **Settings > General > VPN & Device Management**, find the developer entry for your Apple ID, and tap **Trust**. Then run the app again from Xcode.

### iPhone Not Appearing in Xcode Device List

- Make sure your cable supports data transfer. Some cables are charge-only and will not work.
- Try a different USB port on your Mac.
- Check that you tapped **Trust** on the "Trust This Computer?" dialog on your iPhone.
- Restart Xcode. Sometimes the device list does not refresh until Xcode is relaunched.
- Make sure your iPhone is unlocked when you connect it.

### Provisioning Profile or Signing Errors

- Verify that **Automatically manage signing** is checked in the **Signing & Capabilities** tab.
- Make sure a **Team** is selected in the dropdown (not `[None]`).
- If you are using a free Apple ID account, the Bundle Identifier must be unique. Try changing it to something like `com.yourname.PandaAutomator` in the **Signing & Capabilities** tab.
- If errors persist, try signing out of your Apple ID in **Xcode > Settings > Accounts**, then signing back in.

### App Crashes Immediately on Launch

- In Xcode, go to **Product > Clean Build Folder** (or press **Shift+Cmd+K**), then click **Run** again.
- Make sure your iPhone is running **iOS 16.0 or later**. PandaAutomator requires iOS 16.0 as a minimum.
- If the crash continues, check the Xcode console (bottom panel) for error messages.

### Free Account 7-Day Expiry

With a free Apple ID, apps you sideload expire after 7 days. When this happens, the app will no longer open on your iPhone. To fix this, simply connect your iPhone to your Mac and click **Run** in Xcode again to reinstall the app. A paid Apple Developer account ($99/year) removes this limitation entirely.
