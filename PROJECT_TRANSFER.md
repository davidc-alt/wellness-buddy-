# 🌿 Wellness Buddy — Project Handoff & Technical Documentation

> **Project Name**: Wellness Buddy  
> **Repository**: [https://github.com/davidc-alt/wellness-buddy-.git](https://github.com/davidc-alt/wellness-buddy-.git) (`main` branch)  
> **Local Directory**: `/Users/davidbondarescu/WellnessBuddy`  
> **Live Web Application**: [https://wellness-buddy-vduz.onrender.com](https://wellness-buddy-vduz.onrender.com)  
> **Last Updated**: August 2026  

---

## 📍 1. Repository & Local Setup Overview

| Component | Path / Detail | Function |
| :--- | :--- | :--- |
| **Backend Entry** | `backend/server.js` | Node.js HTTP server managing JSON persistence (`data.json`), REST APIs, and client/practitioner live state. |
| **Web Frontend** | `backend/public/index.html` | Practitioner Studio & Patient Web Portal with real-time live sync and full protocol management. |
| **iOS Project** | `WellnessBuddy/` | Native SwiftUI application for iOS 16+ supporting patient tracking, push notifications, and live sync. |
| **Xcode Generator** | `generate_xcodeproj.py` | Python script to deterministically regenerate `WellnessBuddy.xcodeproj/project.pbxproj`. |
| **Handoff Document** | `PROJECT_TRANSFER.md` | Authoritative handoff documentation. |

---

## 🎨 2. Design System & Brand Palette

Wellness Buddy uses a calm, integrative health design system with curated HSL color tokens and custom glassmorphic components:

- **Sage Muted Green**: `#5C8B7D` (`Color.paletteSage`)
- **Deep Ocean Slate Blue**: `#2F6B87` (`Color.paletteOcean`)
- **Cool Muted Silver**: `#A7B0B4` (`Color.paletteSilver`)
- **Soft Light Grey**: `#EDEFF0` (`Color.paletteSoftBg`)
- **Dark Charcoal Text**: `#354047` (`Color.paletteDark`)
- **Official Brand Emblem**: Blue/Green gradient circle (`#5C8B7D` to `#2F6B87`) with modern centered white **"wb"** typography (`WellnessBuddyLogoView`).

---

## 🚀 3. Core Features & Capabilities

### 🩺 A. Practitioner Studio (Web & App)
1. **Prescription Management**:
   - Add new supplements/peptides with specific dosage, units (`caps`, `mg`, `mcg`, `IU`, `mL`, `sprays`), timing schedule (`Empty Stomach`, `With Breakfast`, `With Meal`, `Pre-Workout`, `Before Bed`), and practitioner notes.
   - **Repeat Intervals**: Assign dose frequency intervals (4h, 6h, 8h, 12h, 24h, 48h).
   - **Edit Prescribed Items**: Click `✏️ Edit` on any prescribed supplement to update dosage, brand, interval, or notes in place.
   - **⚡ Quick Stack Preset**: 1-Tap prescription of common protocols (*NAD+ Liposomal Concentrate*, *BPC-157 Oral Supplement*, *Liposomal Vitamin D3 + K2*).
2. **Clean Default State & Roster Management**:
   - Starts cleanly with 0 default patients (`clients: []` in `data.json`).
   - Practitioners can delete individual patients (`🗑️`) or clear the roster (`Clear Roster (0 Patients)`).

### 📱 B. Patient Experience (iOS & Web Portal)
1. **Dynamic Pill Status & Card Badges**:
   - Displays real-time countdown timer to next dose (e.g., *"Next in 5h 30m"*).
   - When dose is due, card switches to **DUE NOW** badge, active banner pops up, and **Done** & **Wait** buttons appear.
   - Tapping **Done** logs the dose, hides the pop-up banner, hides the "Done" button, and displays a `✓ Dose Completed` seal badge until the next dose interval arrives.
2. **Push & In-App Notifications**:
   - Sends automated local push notifications when a pill is due or when a practitioner updates a prescription.
   - Prompts for notification permissions on launch/login with an in-app "Enable Notifications" card.
3. **Fullscript External Dispensary Link**:
   - Tapping **Refill** or **1-Tap Refill** opens `https://us.fullscript.com/welcome/lvitti/signup` directly in external Safari via `UIApplication.shared.open(...)`.
4. **Session Auto-Restore & Server Re-Sync**:
   - When a patient opens the app after a server restart or fresh deploy, the app automatically calls `/api/auth/restore-session`.
   - Restores patient profile (Name, DOB, Goal, Symptoms) and assigned supplement stack to `data.json` and updates the Practitioner Studio roster live!

---

## ⚡ 4. Technical Architecture & Performance Optimizations

1. **Redundant Re-Render Prevention**:
   - `PractitionerProtocol` and `ActiveReminderState` conform to `Equatable`.
   - `fetchLiveProtocol()` checks `if self.currentProtocol != liveProto` before updating `@Published` state, eliminating main thread stuttering and frame drops.
2. **Static Shared Date Formatters**:
   - `APIService` uses thread-safe static `ISO8601DateFormatter` instances to prevent high-frequency memory allocations during 5s live polling cycles.
3. **Deterministic Stable UUID Hashing**:
   - Added `toStableUUID` String extension to map string IDs from backend into stable UUIDs, fixing reminder dismissal state mismatches.
4. **Physical iOS Device Deployment**:
   - `generate_xcodeproj.py` configures `CODE_SIGN_STYLE = Automatic` and `"CODE_SIGN_IDENTITY[sdk=iphoneos*]" = "Apple Development"` for seamless deployment on physical iPhones.

---

## 🛠️ 5. Key File Index

- [`backend/server.js`](file:///Users/davidbondarescu/WellnessBuddy/backend/server.js): Node.js HTTP server & REST APIs (`/api/auth/restore-session`, `/api/protocol/:clientId`, `/api/practitioner/assign-protocol/:clientId`).
- [`backend/public/index.html`](file:///Users/davidbondarescu/WellnessBuddy/backend/public/index.html): Web portal frontend (Practitioner Studio & Patient Portal).
- [`WellnessBuddy/Services/APIService.swift`](file:///Users/davidbondarescu/WellnessBuddy/WellnessBuddy/Services/APIService.swift): API network service.
- [`WellnessBuddy/Services/FullscriptService.swift`](file:///Users/davidbondarescu/WellnessBuddy/WellnessBuddy/Services/FullscriptService.swift): Fullscript dispensary integration & external browser launcher.
- [`WellnessBuddy/Services/NotificationService.swift`](file:///Users/davidbondarescu/WellnessBuddy/WellnessBuddy/Services/NotificationService.swift): UNUserNotificationCenter push notification manager.
- [`WellnessBuddy/ViewModels/WellnessBuddyViewModel.swift`](file:///Users/davidbondarescu/WellnessBuddy/WellnessBuddy/ViewModels/WellnessBuddyViewModel.swift): Main application state & live sync manager.
- [`WellnessBuddy/Components/CalmDesignComponents.swift`](file:///Users/davidbondarescu/WellnessBuddy/WellnessBuddy/Components/CalmDesignComponents.swift): Custom design system UI components & `WellnessBuddyLogoView`.
- [`generate_xcodeproj.py`](file:///Users/davidbondarescu/WellnessBuddy/generate_xcodeproj.py): Xcode project generator script.

---

## 🚀 6. How to Run & Deploy

### A. Run Backend Locally
```bash
cd /Users/davidbondarescu/WellnessBuddy/backend
node server.js
```
Access live portal at `http://localhost:3000`.

### B. Regenerate Xcode Project & Run iOS App
```bash
python3 generate_xcodeproj.py
```
Open `WellnessBuddy.xcodeproj` in Xcode, select your target (Simulator or physical iPhone), and press **⌘R**.

### C. Commit & Push to GitHub (Triggers Render Auto-Deploy)
```bash
git add .
git commit -m "Update Wellness Buddy application"
git push origin main
```
Live deployed at: [https://wellness-buddy-vduz.onrender.com](https://wellness-buddy-vduz.onrender.com)
