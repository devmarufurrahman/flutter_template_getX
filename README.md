---
# 🚀 Flutter Ultimate Automation Starter
### *Empowering Developers with Clean Architecture & Instant Boilerplate*

Developed and maintained by **[devmarufurrahman](https://github.com/devmarufurrahman)**.
---

## 💻 System Prerequisites

Before running the automation script, ensure your machine has the following installed:

1.  **Flutter SDK:** (Version 3.10.4 or higher recommended)
2.  **Dart SDK:** (Included with Flutter)
3.  **Git:** (For version control)
4.  **IDE:** VS Code or Android Studio with Flutter/Dart plugins.
5.  **RPS Package:** Active globally by running:
    `dart pub global activate rps`

---

## 🛠️ How to Use & Run

### 1. Project Generation

Run the main automation script from your terminal:

```bash
dart flutter_temp.dart
```

_Input your project name (e.g., `my_awesome_app`) when prompted._

### 2. Mandatory: Add Roboto Font 🔠

The generated architecture uses **Roboto** as the default font. You **MUST** add it before running the app to avoid UI issues.

1.  **Download:** Download the Roboto font family from [Google Fonts](https://fonts.google.com/specimen/Roboto).
2.  **Place Files:** Create a folder `assets/fonts/` (if not already there) and paste the `.ttf` files.
3.  **Update Pubspec:** Ensure your `pubspec.yaml` contains:
    ```yaml
    flutter:
      fonts:
        - family: Roboto
          fonts:
            - asset: assets/fonts/Roboto-Regular.ttf
            - asset: assets/fonts/Roboto-Bold.ttf
              weight: 700
    ```

### 3. Post-Setup Commands (Step-by-Step)

After generating the project and adding fonts, run these commands in order:

```bash
# 1. Navigate to your project
cd your_project_name

# 2. Install all dependencies
flutter pub get

# 3. Generate Localization (L10n)
flutter gen-l10n

# 4. Generate Assets & Boilerplate code
dart run rps gen

# 5. Finally, Run the App
flutter run
```

---

## 🏗️ Folder Architecture

A **Feature-based Clean Architecture** designed for massive scalability:

```text
lib/
├── app.dart                # Main App Widget (ScreenUtil, Theme, Routing)
├── main.dart               # Entry point (Service Initialization)
├── core/
│   ├── bindings/           # Global Bindings (InitialBinding)
│   ├── common/             # Global Widgets, Styles, and Models
│   ├── network/            # Dio Configuration & HttpMethods
│   ├── services/           # Storage, Notification, Media, Location services
│   ├── theme/              # Light/Dark Theme & Custom Component Themes
│   └── utils/
│       ├── constants/      # App Colors, Paths, API Endpoints, Imports
│       ├── device/         # Device & Platform specific utilities
│       ├── formatters/     # Date, Currency, and Phone formatters
│       ├── helpers/        # Snackbars, Dialogs, and UI helpers
│       ├── logging/        # Structured Console Logging (AppLogger)
│       └── validators/     # Form Validation logic
├── feature/                # Feature modules (Splash, Auth, etc.)
│   └── [feature_name]/
│       ├── binding/
│       ├── controller/
│       ├── repository/
│       └── view/
├── router/                 # GetX Routing (AppPages & AppRoutes)
└── l10n/                   # Multi-language (ARB files)
```

---

## ⚡ Feature Automation

In your project root, you will find `create_feature.dart`. Use it to generate a complete module instantly.

**Command:**

```bash
dart create_feature.dart <feature_name>
```

_Example:_ `dart create_feature.dart login`

**Automation Highlights:**

- Creates all sub-folders (`view`, `controller`, etc.).
- Generates clean boilerplate code.
- **Auto-Exports:** Adds exports to `lib/core/utils/constants/imports.dart`.
- **Auto-Route:** Updates `lib/router/app_routes.dart` and `lib/router/app_pages.dart`.

---

## 📦 Key Packages Included

- **State Management:** GetX
- **Networking:** Dio & PrettyDioLogger
- **Storage:** GetStorage & SharedPreferences
- **UI/UX:** ScreenUtil, Lottie, SVG, Google_Fonts
- **Services:** Firebase (Messaging, Analytics, Crashlytics), Geolocator

---

## 🚦 Usage Guidelines

- **Network:** Use the `HttpMethod` class for API calls.
- **Logs:** Use `AppLoggerHelper` for colored console logs.
- **Imports:** Only one import is needed for most files:
  `import 'package:your_project/core/utils/constants/imports.dart';`

---

## 📜 Copyright & License

Designed and Automated by **devmarufurrahman**.

> _"Code is poetry, automation is the rhythm."_

© 2026 | **devmarufurrahman** | All Rights Reserved.

---
