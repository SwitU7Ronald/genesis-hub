# Genesis Hub Multi-Platform Strategy & Firebase Plan

Based on your company structure, we need to separate the app's features heavily based on the device being used. Field workers (Mobile) have different needs than Office Admins (Desktop/Web).

## 1. Feature to Platform Mapping

Here is the strategy on which features belong to which platforms. We will implement UI constraints so that the app intelligently adapts based on whether it is running on a phone or a PC.

### 📱 Field Workers (Android / iOS)
The mobile app is for **on-site execution and data collection**.
- **Hardware Scanner**: Exclusively on mobile. Employees use phone cameras to scan solar panel barcodes/inverters to log them into the system.
- **Document Scanner**: Exclusively on mobile. Employees use cameras to take photos of site layouts or client IDs (with your Geo-tagging feature).
- **Client Quick-View**: View basic details of the client they are currently visiting.
- **Inventory Check**: Quickly check if a specific part is in stock before heading to a site.

### 💻 Office Admins (Windows / Mac / Web)
The desktop/web app is for **heavy management, data entry, and analytics**.
- **Full Client Database**: Detailed data entry for client economics, hardware assignment, and viewing uploaded documents.
- **Vendor Registry**: Managing legal witnesses and vendors.
- **Detailed Inventory Management**: Managing stock levels, adding bulk shipments.
- **Command Center (Dashboard)**: The wide grid view you currently have to see the big picture.
- *(Note: The scanner features will be hidden or mocked on Desktop since you don't use a laptop camera to scan physical solar panels).*

---

## 2. Firebase Setup Guide

Since Firebase requires your personal/company Google account, I cannot create the project for you, but I can do all the coding *after* you follow these 3 simple steps.

### Step 1: Create the Project
1. Go to [Firebase Console](https://console.firebase.google.com/).
2. Click **Add Project** and name it `Genesis Hub`.
3. You can disable Google Analytics for now if you want. Click **Create Project**.

### Step 2: Install Firebase CLI tools
Open your computer's terminal (or PowerShell) and run this to install the tools:
```powershell
npm install -g firebase-tools
```
*(If you don't have Node.js installed, let me know, but typically developers do).*

### Step 3: Log in and Configure Flutter
Run these commands one by one in the terminal inside your `genesis-hub` folder:
```powershell
firebase login
```
*(This will open your browser to log into your Google Account).*

```powershell
dart pub global activate flutterfire_cli
```
```powershell
flutterfire configure --project=YOUR_PROJECT_ID
```
*(Replace `YOUR_PROJECT_ID` with the Project ID from your Firebase project settings. It will ask you which platforms to support—press **Enter** to select Android, iOS, Web, macOS, Windows).*

> [!IMPORTANT]
> **Action Required:** Once you finish Step 3, the generic `firebase_options.dart` file I created will be replaced by your real one. Tell me when you've done this, and I will write the code to connect your users, clients, and inventory to the database!

## User Review Required
Please review the Feature-to-Platform mapping above. If it perfectly matches how your company operates:
1. Approve this plan.
2. Follow the 3 Firebase setup steps.
3. Let me know when `flutterfire configure` is complete!
