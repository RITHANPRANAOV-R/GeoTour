# 🌍 GeoTour

GeoTour is a comprehensive, state-of-the-art Flutter mobile application designed to ensure tourist safety by seamlessly integrating **Tourists**, **Medical Facilities**, and **Police Departments**. By leveraging real-time geo-intelligence and AI-powered monitoring, GeoTour provides a critical safety net for travelers in any environment.

## ✨ Core Ecosystem

### 🌴 Tourist Module (Safety First)
- **AI-Powered Geofencing:** Automated SOS triggers when entering high-risk or restricted zones.
- **Broadcast SOS Network:** One-tap emergency alerts that reach all nearby responders simultaneously.
- **Digital Health Passport:** Secure storage of medical info (blood group, allergies, medications) for instant responder access.
- **Live Spatial Awareness:** Real-time map interface with geofence visualization.

### 🏥 Medical Module (Rapid Response)
- **Omni-Broadcast Dashboard:** Immediate reception of broadcasted medical alerts from any nearby tourist.
- **Case Lifecycle Management:** Confirm, treat, and complete medical emergencies with a specialized workflow.
- **Intelligent Referrals:** Seamlessly transfer high-complexity cases to specialized hospitals with full data parity.
- **Medical Report Access:** Secure viewing and downloading of patient health records from the cloud.

### 🚓 Police Module (Mission Control)
- **Live Mission Tracking:** Real-time OSRM-powered route navigation between officers and victims.
- **Dynamic Risk Categorization:** Instant visual indicators for Extreme, High, and Medium risk incidents.
- **Unit Availability System:** Real-time duty status management (Available, Offline, On Mission).
- **Inter-Service Communication:** Integrated coordination tools for complex multi-agency responses.

## 🎨 Design Philosophy
GeoTour features a **Premium Glassmorphic Interface** that blends aesthetics with high-stakes functionality:
- **Frosted-Glass UI:** Modern, clean, and intuitive design that remains readable in high-stress situations.
- **Fluid Micro-Animations:** Buttery-smooth transitions and haptic feedback for a "live" application feel.
- **Adaptive Performance:** Optimized for 60fps/120fps across all devices, ensuring zero lag during emergencies.

## 🛠 Tech Stack
- **Frontend:** Flutter & Dart (High-performance UI rendering)
- **Backend:** Firebase (Firestore for real-time data, Firebase Auth for secure identity)
- **Cloud Storage:** Cloudinary (Secure storage for medical reports and images)
- **Navigation:** OSRM (Open Source Routing Machine) for real-time route calculations
- **Geo-Intelligence:** Custom Geofencing and Proximity algorithms

### Structure

```text
GeoTour/
├── lib/
│   ├── models/            # Data models (Alert, Hospital, Officer, Trip)
│   ├── screens/           # UI Screens grouped by user role
│   │   ├── admin/         # Admin dashboard and controls
│   │   ├── auth/          # Login and registration screens
│   │   ├── common/        # Shared screens and utilities
│   │   ├── hospital/      # Hospital case management and dashboard
│   │   ├── police/        # Police incident management screens
│   │   └── tourist/       # Tourist dashboard, SOS, and maps
│   ├── services/          # Core business logic and Firebase API calls
│   ├── widgets/           # Reusable custom UI components
│   ├── firebase_options.dart # Generated Firebase configuration
│   └── main.dart          # Application entry point
├── pubspec.yaml           # Flutter dependencies and assets configuration
└── README.md              # Project documentation
```

## 🚀 Getting Started

### 💻 Hardware and Software Requirements

**Key Accounts/Prerequisites**
- **Firebase Account:** With Firestore and Auth enabled.
- **Cloudinary Account:** Required for medical and health report uploads.

**Software Requirements**
- **Operating System:** Cross-Platform (Windows, MacOS, Linux for Development; Android, iOS for Mobile App)
- **Runtime & SDKs:** Flutter SDK (Version `3.10.x` or higher), Dart SDK (comes with Flutter)
- **Database:** Firebase Cloud Firestore (NoSQL Cloud Database)

**Development Tools**
- **Dart:** For object-oriented application development
- **Flutter:** UI toolkit for building natively compiled cross-platform applications
- **Firebase Services:** Authentication, Core integration, and Database
- **Flutter Map:** Interactive maps and routing implementation
- **Geolocator:** Location services and GPS integration
- **Cloudinary:** Cloud-based media management and image hosting

**Hardware Requirements (Development Machine)**
- **Processor:** Quad-core CPU
- **Memory:** 8 GB RAM or more (16 GB recommended for emulators)
- **Storage:** At least 10 GB of available disk space
- **Network:** Stable internet connection with adequate bandwidth

**Software Tools to Build and Run the Project**
- **Code Editor:** Visual Studio Code / Android Studio
- **Version Control:** Git
- **Package Management:** Flutter Pub (pub tool)
- **Database Management:** Firebase Console
- **API Testing:** Postman
- **Deployment Platforms:** Google Play Store, Apple App Store, Firebase App Distribution

### 📥 Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/RITHANPRANAOV-R/GeoTour.git
   ```
2. **Setup Firebase:**
   - Add your `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) to the respective directories.
3. **Install dependencies:**
   ```bash
   flutter pub get
   ```
4. **Run the application:**
   ```bash
   flutter run --no-impeller # (Use --no-impeller if experiencing shader issues)
   ```

## 🤝 Contributing
Contributions are what make the open-source community such an amazing place to learn, inspire, and create. Any contributions you make are **greatly appreciated**.
