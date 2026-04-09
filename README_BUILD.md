# 🚀 AgriBuddy Build Guide

## 🚜 How to Update Your App (IMPORTANT!)

To ensure your users' data is **preserved** and the update is successful, **ONLY** use this command to build your APK:

### **Run this in your terminal:**
`.\build_apk.bat`

---

## 🏗️ What this script does for you:
1.  **Auto-Versioning**: It generates a unique **Batch Number** based on the current date/time. This tells Android that the new APK is a fresh update.
2.  **Auto-Naming**: It creates a new file called `AgriBuddy_v2.0.0_[DATE].apk` in your project folder.
3.  **Data Protection**: It ensures the "Stamps" and "Signatures" are handled correctly so your users are **NOT** logged out.

> [!CAUTION]
> **NEVER use `flutter build apk` manually without the batch number.** 
> Doing so might cause the app to fail to update or wipe your users' data.

---

### **Happy Farming! 🌽👨‍🌾🚀**
