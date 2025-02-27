# Solar Browser Mobile

Solar Browser is a Flutter-based web browser for mobile. It uses **WebView for Flutter** as its core. Additionally, I aim to release a **C++ version** of Solar Browser, which will utilize **Firefox's Gecko web engine** instead of the Chromium-based engine.

Thank you for your support!

---

## Features (Planned and Current)
- **Current:**
  - Flutter-based application using WebView for Flutter.
  - Easy-to-run setup for developers.

- **Future:**
  - C++ version with Gecko web engine for enhanced performance and compatibility.

---

## How to Run?
This section is for those who want to run Solar Browser when no releases are available in the [Releases](#) tab or on the official website. It is also intended for developers contributing to the project.

### Prerequisites
1. **Install Flutter SDK**:
   - Follow the official Flutter installation guide for your operating system: [https://flutter.dev/docs/get-started/install](https://flutter.dev/docs/get-started/install).
   - Ensure to add Flutter to your system path as part of the installation process.

2. **Install Required Dependencies**:
   - Open a terminal and navigate to the project folder.
   - Run the following command to fetch the required packages:

     ```bash
     flutter pub get
     ```

### Running Solar Browser
1. Once the dependencies are installed, ensure you have an emulator or a physical device connected.
2. Run the application using the following command:

   ```bash
   flutter run --release or flutter run --debug
   ```

3. Alternatively, you can build the project for release using:

   ```bash
   flutter build apk
   ```

   The generated APK file can be found in the `build/app/outputs/flutter-apk/` directory.

---

## For Developers
For more detailed developer instructions, refer to the [Developer Guide](For%20Developers.md).

---

## Roadmap
- **Version 0.x**:
  - Continued improvements and feature enhancements for the Flutter-based browser.
- **Version 1.0+**:
  - Transition to the C++ version with Gecko web engine.

---

### Thank You!
Your support means everything! If you encounter issues or have suggestions, feel free to contribute or report them via the [GitHub Issues](https://github.com/solarbrowser/mobile/issues) page.

