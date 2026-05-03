# 🌍 GeoTour

GeoTour is a comprehensive, cutting-edge Flutter mobile application designed to ensure tourist safety by seamlessly integrating tourists, hospitals, and police departments during emergency situations. The application features a stunning, premium glassmorphic UI design, providing an intuitive, buttery-smooth user experience.

## ✨ Key Features

### 🌴 Tourist Module
- **Interactive Dashboard:** Dynamic and user-friendly interface for immediate access to necessary tools.
- **Emergency Response System:** Fast SOS alerts connecting straight to the local emergency network.
- **Medical Profile:** Pre-setup critical medical information for life-saving quick references.
- **Live Maps:** Integrated map interface to maintain spatial awareness.

### 🏥 Hospital Module
- **Case Management:** Streamlined system to handle active incoming emergencies and process case transfers.
- **Referral System:** Efficient dashboards to manage "Active" hospital statuses.
- **Premium Notifications:** Clear, non-intrusive custom "PremiumToast" alerts.

### 🚓 Police Module
- **Incident Management:** Detailed tracking and overview of ongoing incidents.
- **Command Dashboard:** Centralized real-time hub for police departments.

## 🎨 Design & Performance

GeoTour brings a highly optimized user experience:
- **Glassmorphism Aesthetics:** A modern, frosted-glass interface that feels extremely premium.
- **Fluid Animations:** Refined transitions (like beautiful FadeTransitions) and micro-animations that make the app feel alive.
- **Highly Optimized:** Engineered with global optimizations to minimize jank and deliver an uncompromising 60fps/120fps experience.

### Structure

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

1. Clone the repository:
   ```bash
   git clone https://github.com/RITHANPRANAOV-R/GeoTour.git
   ```
2. Navigate to the project directory:
   ```bash
   cd GeoTour
   ```
3. Fetch dependencies:
   ```bash
   flutter pub get
   ```
4. Run the app:
   ```bash
   flutter run
   ```

## 🤝 Contributing
Contributions, issues, and feature requests are always welcome! Feel free to check the issues page.

---
*Built with ❤️ for a safer travel experience.*
