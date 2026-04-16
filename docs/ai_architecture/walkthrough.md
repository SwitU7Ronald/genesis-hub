# Multi-Platform Restrictions Configured

I have successfully restricted features to match your exact company roles:

## 1. Desktop & Web Constraints
- I updated the **Hardware Tab** to detect if it's running on a desktop or web environment. If so, the physical "Scan" button is entirely hidden, and only the "Type" button is available since you don't use laptops to scan hardware serials.
- I updated the **Documents Tab**. You will no longer see the "Camera" or "Scan" options on PCs, only the "Attach" option, streamlining the interface for Office Admins uploading PDFs or images from local storage.

## 2. Mobile Access
- If you open the same app on an iPhone or Android, the App recognizes the environment and automatically restores the **Camera** and **Hardware QR Scanner** features.

---

## Final Step: Firebase Setup Guide
Since I do not have access to your Google Account, I cannot create the database for you. But I can guide you through it right now. Please follow these exact steps:

**Step 1:** Go to the [Firebase Console](https://console.firebase.google.com/) and create a new project called `Genesis Hub`.

**Step 2:** Open a terminal on your computer and install the tools by running:
```powershell
npm install -g firebase-tools
```

**Step 3:** Log into Firebase via terminal:
```powershell
firebase login
```
*(This opens your browser to log in).*

**Step 4:** Link the Flutter app to Firebase by running:
```powershell
dart pub global activate flutterfire_cli
flutterfire configure
```
*(When prompted, select your new Genesis Hub project and press Enter to select the platforms).*

Once you run these commands, Firebase will overwrite my placeholder `firebase_options.dart` with your real database credentials, and we will be done!
