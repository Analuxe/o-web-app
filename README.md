# O Web App

A Flutter-based web frontend for the **O** platform, designed to harmonize with the mobile experience while optimizing for desktop browsers.

## 🎨 Design System
- **Theme**: Dark-mode dominant
- **Primary Color**: Neon Pink (`#FF4FA3`)
- **Secondary Color**: Soft Rose (`#FF8BC8`)
- **Background**: Black (`#000000`) / Deep Charcoal (`#0D0D0D`)
- **Typography**: Inter

## 🚀 Getting Started

1.  **Install Flutter**: Ensure you have the Flutter SDK installed and configured for web.
2.  **Fetch Dependencies**:
    ```bash
    flutter pub get
    ```
3.  **Run Locally**:
    ```bash
    flutter run -d chrome
    ```

## 📂 Project Structure
- `lib/theme.dart`: Core design system implementation.
- `lib/app_shell.dart`: Responsive layout with side navigation bar.
- `lib/screens/`: Feature screens (Discovery, Messaging).
- `lib/services/`: Shared backend logic (Supabase).
- `assets/`: Brand assets including the historical logo.

## 🔗 Backend Integration
This app connects to the same Supabase backend as the mobile version. Update `lib/services/supabase_service.dart` with your production credentials if they differ from the development environment.
