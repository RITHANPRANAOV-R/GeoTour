# GeoTour Project Modules Documentation

This document provides a comprehensive overview of the architectural modules within the GeoTour Flutter application. The project is structured into distinct feature-based modules, ensuring separation of concerns and maintainability.

## 1. Authentication Module (`lib/screens/auth`)
This module handles all user identification, registration, and role-based access control.

*   **Key Screens:**
    *   `splash_screen.dart` / `get_started_screen.dart`: Initial app entry points.
    *   `sign_in_screen.dart` / `sign_up_screen.dart`: Standard email/password authentication.
    *   `admin_login_screen.dart`: Dedicated login portal for system administrators.
    *   `google_initial_role_selection.dart` / `post_auth_role_selection.dart`: Screens to assign roles (Tourist, Police, Hospital) to newly authenticated users.
    *   `auth_wrapper.dart`: Logic to determine which screen to show based on the user's current authentication state.
*   **Associated Services:** `lib/services/auth_service.dart`

## 2. Tourist Module (`lib/screens/tourist`)
The core user-facing module designed for tourists using the application for safety and navigation.

*   **Key Screens:**
    *   `dashboard_screen.dart`: The main hub for tourists.
    *   `emergency_response_screen.dart`: Critical screen for triggering SOS and handling emergencies.
    *   `maps_screen.dart` / `location_picker_screen.dart`: Map integration and location services.
    *   `trips_screen.dart` / `trip_history_screen.dart` / `trip_detail_screen.dart`: Trip creation and management.
    *   `profile_screen.dart` / `tourist_profile_setup.dart` / `medical_info_setup_screen.dart`: User profile and vital medical information management.
    *   `alerts_screen.dart` / `alert_detail_screen.dart`: Viewing active geofence or system alerts.
    *   `police_chat_screen.dart`: Direct communication channel with assigned police officers.
*   **Associated Models:** `lib/models/trip_model.dart`
*   **Associated Services:** `lib/services/trip_service.dart`

## 3. Police Module (`lib/screens/police`)
Designed for law enforcement personnel to monitor tourists, respond to incidents, and manage resources.

*   **Key Screens:**
    *   `police_dashboard.dart` / `police_dashboard_choice.dart`: Main dashboard with tabbed navigation (e.g., Home, Incidents).
    *   `police_home.dart`: Overview of the station's current status and map view.
    *   `incidents.dart`: List of active and past emergency incidents.
    *   `victim_details.dart`: Detailed view of an incident, including the tourist's information and location.
    *   `assign_officers.dart`: Interface for assigning specific officers to cases.
    *   `police_profile_screen.dart` / `police_profile_setup.dart`: Station/Officer profile management.
*   **Associated Models:** `lib/models/officer_model.dart`
*   **Associated Services:** `lib/services/police_service.dart`

## 4. Hospital Module (`lib/screens/hospital`)
Designed for medical facilities to receive and manage emergency medical cases.

*   **Key Screens:**
    *   `hospital_dashboard.dart`: Main interface for hospital staff.
    *   `hospital_home.dart`: Overview of the hospital's active status and map.
    *   `hospital_cases.dart`: Management of incoming and active patient cases.
    *   `patient_details.dart`: Medical and emergency details of an incoming patient.
    *   `hospital_profile_screen.dart` / `hospital_profile_setup.dart`: Hospital information and availability management.
*   **Associated Models:** `lib/models/hospital_model.dart`
*   **Associated Services:** `lib/services/hospital_service.dart`

## 5. Admin Module (`lib/screens/admin`)
Used by system administrators to oversee the entire platform, manage users, and configure system settings.

*   **Key Screens:**
    *   `admin_home.dart`: Central control panel.
    *   `user_access_control.dart`: Management of user roles, permissions, and account statuses.
    *   `geofence_management.dart`: Creation and management of safe/danger zones on the map.
    *   `incident_logs.dart`: Comprehensive history of all system-wide incidents.
    *   `system_monitoring.dart`: System health and activity metrics.
    *   `admin_profile_setup.dart`: Admin account settings.
*   **Associated Services:** `lib/services/admin_api_service.dart`

## 6. Shared Components & Infrastructure

### Common Screens (`lib/screens/common`)
Screens utilized across multiple user roles:
*   `call_screen.dart`: Audio/Video calling interface.
*   `report_viewer_screen.dart`: Interface for viewing generated PDF reports.

### Services (`lib/services`)
Core business logic and external integrations:
*   `alert_service.dart`: Handles geofence and system-wide push notifications/alerts.
*   `chat_service.dart`: Real-time messaging infrastructure (e.g., between Tourist and Police).
*   `file_service.dart`: File uploading, downloading, and storage management.
*   `geo_service.dart` / `location_service.dart`: Geolocation tracking, geofencing logic, and map utilities.
*   `user_service.dart`: General user data manipulation.

### Global Widgets (`lib/widgets`)
Reusable UI components ensuring a consistent design language across the app:
*   `premium_toast.dart` / `premium_dialog.dart` / `premium_input_dialog.dart`: Custom glassmorphic notifications and modals.
*   `app_drawer.dart`: Global navigation drawer.
*   `logout_dialog.dart`: Standardized logout confirmation.

### Data Models (`lib/models`)
Data structures used throughout the application:
*   `alert_model.dart`
*   `hospital_model.dart`
*   `officer_model.dart`
*   `trip_model.dart`
