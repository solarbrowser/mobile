# Solar Browser Mobile

**Solar Browser** is a Flutter-based web browser for mobile. It uses **WebView for Flutter** as its core. Additionally, a **C++ version** of Solar Browser is planned, which will utilize the custom **Solarist Web Engine** instead of a Chromium-based backend.

> ⚠️ **Notice:** This is currently a prototype. Please do not treat it as a production-ready browser. It's meant to gather early feedback and test concepts. So before asking *"is this even a browser?"*, check the roadmap. 🙂

---

## ✨ Features (Current & Planned)

### ✅ Current:
- **Flutter-based application** using WebView for Flutter.
- **Speed** – lightweight and responsive.
- **Customizability** – adjustable UI and features for user preferences.
- **Easy-to-run setup** for developers.

### 🔮 Planned:
- **C++ version** with Solarist Web Engine for enhanced performance, privacy, and platform control.

---

## 🚀 Roadmap

| Version      | Description                                                                 |
|--------------|-----------------------------------------------------------------------------|
| `0.x`        | Ongoing improvements to the Flutter-based WebView version                  |
| `1.0.0`      | Transition starts toward the C++ version using the Solarist Web Engine     |
| **Late 2025**| **Public beta release of the Solarist Web Engine (likely desktop-first)**  |

> Note: **Solar Browser Mobile will continue to use WebView for a while**, even after the Solarist engine becomes available.

---

## 📦 How to Run?

This section is for those who want to run Solar Browser locally when no releases are available in the [Releases](#) tab or on the official website. It’s also for contributors.

### ✅ Prerequisites

1. **Install Flutter SDK**  
   - Follow the official Flutter installation guide for your OS:  
     [https://flutter.dev/docs/get-started/install](https://flutter.dev/docs/get-started/install)  
   - Make sure to add Flutter to your system `PATH`.

2. **Install Required Dependencies**

   Navigate to the project folder and run:

   ```bash
   flutter pub get

▶️ Running Solar Browser
Make sure you have a device or emulator connected, then run:
  ```
  flutter run --release
  ```
or for debug mode:
  ```
  flutter run --debug
  ```

📱 Building APK
To build the project for release:
  ```
  flutter build apk
  ```
The generated APK will be located at:
  ```
  build/app/outputs/flutter-apk/app-release.apk
  ```

💬 Disclaimer
This project is a prototype, not a finished product.

Solar engine is not yet integrated into the mobile version.

The current version focuses on speed and user customizability.

Hateful feedback is noise. Useful feedback is gold. Choose wisely

🙏 Thank You!
Your support means everything!
If you encounter issues or have suggestions, feel free to contribute or report them via the GitHub Issues page.

Stay tuned for the Solarist Engine Beta — coming late summer 2025!

