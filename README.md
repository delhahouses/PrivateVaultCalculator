# Private Vault Calculator

[![Build Android Release APK](https://github.com/your-username/private-vault-calculator/actions/workflows/android-release.yml/badge.svg)](https://github.com/your-username/private-vault-calculator/actions/workflows/android-release.yml)

A premium, production-ready Flutter 3.x Android and iOS application designed as a realistic mathematical calculator with a hidden, secure private vault for organizing and storing personal media and document files locally on the device.

---

## CI/CD Pipeline & Cloud Builds

This project is pre-configured with a robust Continuous Integration / Continuous Deployment (CI/CD) pipeline using **GitHub Actions**. 

Whenever code is pushed to the `main` or `master` branches, or when a Pull Request is opened, the automated workflow:
1.  Sets up a clean **Ubuntu VM**.
2.  Configures **Java 17 (OpenJDK)**.
3.  Installs the stable channel of the **Flutter SDK**.
4.  Caches the Flutter compiler, Pub packages, and Gradle wrapper objects to maximize build speeds.
5.  Downloads project dependencies (`flutter pub get`).
6.  Checks code quality via static analysis (`flutter analyze`).
7.  Compiles the project into a release APK (`flutter build apk --release`).
8.  Uploads the compiled APK as a secure build artifact.

### How to Download the Cloud-Generated APK:
1.  Navigate to your repository page on GitHub.
2.  Click on the **Actions** tab.
3.  Select the latest workflow run from the list.
4.  Scroll down to the **Artifacts** section at the bottom of the run summary page.
5.  Click on **PrivateVaultCalculator-Release** to download the ZIP file containing the `app-release.apk`.

---

## Build Instructions

### Requirements
- **Flutter SDK**: `>= 3.0.0 < 4.0.0` (Stable channel)
- **Java Development Kit (JDK)**: `Java 17` (Zulu OpenJDK 17 recommended)
- **Android SDK**: Build tools and platforms corresponding to API 34 compiling levels.

### 1. Local Build Instructions
To compile and test the application on your local development system:

1.  **Get dependencies**:
    ```bash
    flutter pub get
    ```
2.  **Generate platform files (Optional)**:
    If platform-specific project files (`android/`, `ios/`) need rebuilding, execute:
    ```bash
    flutter create --offline .
    ```
3.  **Run static analysis (Lint check)**:
    ```bash
    flutter analyze
    ```
4.  **Build Release APK**:
    ```bash
    flutter build apk --release
    ```
    The generated APK will be output to:  
    `build/app/outputs/flutter-apk/app-release.apk`
5.  **Build Optional App Bundle (For Play Store distribution)**:
    ```bash
    flutter build appbundle --release
    ```
    The generated App Bundle will be output to:  
    `build/app/outputs/bundle/release/app-release.aab`

### 2. Cloud Build Instructions
To build using GitHub Actions:
1.  Commit and push your changes to your remote repository:
    ```bash
    git add .
    git commit -m "Configure GitHub Actions CI/CD"
    git push origin main
    ```
2.  GitHub will automatically detect the workflow configuration in `.github/workflows/android-release.yml` and initiate the build.
3.  Alternatively, you can manually trigger a build by navigating to the **Actions** tab on your GitHub repository, selecting the **Build Android Release APK** workflow, and clicking the **Run workflow** dropdown button.

---

## Project Structure

```
PrivateVaultCalculator/
├── .github/
│   ├── workflows/
│   │   └── android-release.yml   # CI/CD Workflow file
│   ├── ISSUE_TEMPLATE/
│   │   ├── bug_report.md         # Template for reporting issues
│   │   └── feature_request.md    # Template for requesting new features
│   └── pull_request_template.md  # Guidelines for code pull requests
├── android/                      # Android Platform Configuration
├── ios/                          # iOS Platform Configuration
├── assets/                       # Image assets and custom icons
├── fonts/                        # Font files (Outfit)
├── lib/
│   ├── main.dart                 # App Entry Point & Provider declarations
│   ├── core/
│   │   ├── theme.dart            # Material 3 typography and colors
│   │   └── security.dart         # Hashing & byte-level file cryptography
│   ├── models/
│   │   └── vault_file.dart       # VaultFile & VaultFolder schemas
│   ├── providers/
│   │   ├── settings_provider.dart# Preferences & mock backup provider
│   │   ├── calculator_provider.dart # Calculator logic engine
│   │   ├── auth_provider.dart    # PIN & biometric security provider
│   │   ├── vault_provider.dart   # Encrypted file IO manager
│   │   └── audio_provider.dart   # Playlist & audio playback provider
│   └── views/
│       ├── calculator_view.dart  # Calculator screen
│       ├── auth/
│       │   └── auth_view.dart    # PIN setup and lock screen
│       └── vault/
│           ├── vault_home_view.dart # Vault dashboard & storage details
│           ├── folder_view.dart  # List/Grid file explorer page
│           ├── settings_view.dart# Credentials reset & accents customization
│           └── viewers/
│               ├── image_viewer.dart# photo_view viewer
│               ├── video_viewer.dart# video_player viewer
│               ├── audio_viewer.dart# Audio control buttons and vinyl animation
│               └── pdf_viewer.dart  # flutter_pdfview viewer
├── LICENSE                       # MIT License
├── pubspec.yaml                  # Library definitions & assets config
└── README.md                     # Documentation
```

## Features

- **Realistic Calculator**: Working mathematical logic with a dynamic history panel.
- **Secure PIN Access**: Setup, confirm, and verify a secure 4-digit PIN.
- **Biometric Authentication**: Integrated Fingerprint or Face ID unlocking.
- **On-Device Cryptography**: Rotated XOR byte cipher based on PIN hash protects stored vault files from system file managers.
- **Auto-Lock timeout**: Instantly locks the vault on app backgrounding or inactivity.
- **Premium M3 Design**: Glassmorphic dashboard cards, gradient sheets, customizable accent colors, and custom elastic animations.

## License

This project is licensed under the MIT License - see the [LICENSE](file:///C:/Users/dhsti/Desktop/PrivateVaultCalculator/LICENSE) file for details.
