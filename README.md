# Genesis Hub 🌐

An enterprise-grade, Multi-Platform **Solar Client & Inventory Management System** built with Flutter and Firebase.

## 🚀 Architecture Design

Genesis Hub is built exclusively for a specialized dual-platform deployment tailored to company roles:

### 1. Office Administration (Desktop / Web / Mac)
The desktop application is optimized for high-volume data entry, database analytics, and client management.
- **Enabled:** Dashboard Command Center, Vendor Registry, Client Database, PDF Attaching, and Keyboard Hardware Entry.
- **Disabled:** All Field mobility tools (Physical Barcode Scanners, Realtime Camera features). Hardware components adapt intelligently to remove unsupported native hardware plugins on MacOS and Windows.

### 2. Field Workers (iOS / Android)
The mobile application is an operational tool optimized for on-site inventory execution.
- **Enabled:** QR Hardware Scanner & Realtime Document Scanner.
- Field workers use device cameras to natively upload pre/post-installation site photos and scan inverter bounds directly to the database.

---

## 🛠 Setup & Initialization

### Prerequisites
Before running the application, ensure your machine has:
1. Flutter SDK
2. Node.js (for npm)
3. Firebase CLI

### Connecting Firebase Backend (Mac/Windows)
If you pull this repository on a new machine (like your home Macbook), you must authenticate Firebase before running the app. Run these commands in the terminal:

```bash
# 1. Install Firebase tools (if you haven't globally)
npm install -g firebase-tools

# 2. Login to your Company Google Account
firebase login

# 3. Connect to the genesis-hub-system Database
dart pub global activate flutterfire_cli
flutterfire configure
```
*Note: Make sure your `Pub/Cache/bin` or `.pub-cache/bin` is in your terminal PATH variable.*

---

## 📂 AI Implementation Documentation

During the initial architectural generation, strategic AI decision logs and task tracking were written to the project directory for reference:

- **[Implementation Plan](docs/ai_architecture/implementation_plan.md)**: Strategy around platform constraints and roles.
- **[Task List](docs/ai_architecture/task.md)**: Checklists used during the initial build out.
- **[Walkthrough Logs](docs/ai_architecture/walkthrough.md)**: Summary of how and why certain plugins (like `mobile_scanner`) were conditionally overridden.
