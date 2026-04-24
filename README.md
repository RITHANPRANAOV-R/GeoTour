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

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (`^3.11.0` or higher)
- Firebase Account (with Firestore and Auth enabled)
- Cloudinary Account (for health report uploads)

### Installation

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

---
*Built with ❤️ for a safer, smarter, and more connected travel experience.*
