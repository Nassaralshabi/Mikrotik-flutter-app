# Mikrotik Hotspot Flutter App

A cross-platform Flutter application for managing Mikrotik Hotspot users, plans, and devices. This app provides a modern interface for user registration, login, voucher management, device info, and more, with support for both mobile and web platforms.

## Features
- User registration and login
- Voucher generation and management
- User profile and settings
- Device info and dashboard
- Plan management (add, edit, delete)
- Password reset and verification
- Localization (Arabic/English)
- Responsive UI for mobile and web

## Getting Started

### Prerequisites
- [Flutter SDK](https://flutter.dev/docs/get-started/install) (3.x or later recommended)
- Android Studio, VS Code, or any preferred IDE
- A connected device, emulator, or Chrome for web

### Installation
1. **Clone the repository:**
   ```sh
   git clone <your-repo-url>
   cd mikrotikhotspot
   ```
2. **Install dependencies:**
   ```sh
   flutter pub get
   ```
3. **Run the app:**
   - For Android/iOS:
     ```sh
     flutter run
     ```
   - For Web (Chrome):
     ```sh
     flutter run -d chrome
     ```

## Project Structure
- `lib/` - Main Dart source code
  - `component/` - Reusable UI components
  - `screens/` - App screens and flows
  - `utility/` - API and helper utilities
- `assets/` - Images, fonts, and other assets
- `test/` - Unit and widget tests

## Configuration
- Update API endpoints and credentials in `lib/utility/routerboardservice.dart` as needed.
- Add your own assets (logos, icons) in the `assets/` folder and reference them in `pubspec.yaml`.

## Localization
- The app supports Arabic and English. You can add more languages in the `lib/l10n/` directory.

## License
This project is licensed. See the LICENSE file for details.

## Contact
For support or questions, contact the developer at [amolood@icloud.com](mailto:amolood@icloud.com).
