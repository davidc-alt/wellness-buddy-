# 🌿 Wellness Buddy — Complete Project Transfer & Handoff Document

> **System Overview**: Wellness Buddy is an end-to-end integrative wellness platform and supplement reminder system for health practitioners and male clients. It connects a Node.js backend server, a responsive web studio/portal, and a native SwiftUI iOS app.

---

## 📍 1. Key Repository & Environment Details

- **GitHub Repository**: [`https://github.com/davidc-alt/wellness-buddy-.git`](https://github.com/davidc-alt/wellness-buddy-.git) (`main` branch)
- **Local Directory**: `/Users/davidbondarescu/WellnessBuddy`
- **Backend Entry File**: `backend/server.js` (runs on `http://localhost:3000`)
- **Web Frontend**: `backend/public/index.html`
- **iOS Application**: `WellnessBuddy/` (SwiftUI iOS app targeting iOS 16+)
- **Xcode Generator Script**: `python3 generate_xcodeproj.py`

---

## 🎨 2. Design System & Palette

- **Sage Muted**: `#5C8B7D`
- **Deep Ocean Slate**: `#2F6B87`
- **Cool Muted Silver**: `#A7B0B4`
- **Soft Light Grey Background**: `#EDEFF0`
- **Dark Charcoal Accent**: `#354047`
- **Card Aesthetics**: 24pt rounded pure white minimalist cards with subtle elevation (`.calmCardStyle`).

---

## ⚙️ 3. Current System Behavior & Enforced Rules

1. **Practitioner Identity**:
   - Default practitioner name is **`Practitioner Luba Vitti`** across all backend responses, web views, and iOS app displays.

2. **Patient Registration & Defaults**:
   - Default login form values: Full Name **`Jhon Doe`**, Date of Birth **`1990-01-01`** (placeholder format: `MM-DD-YYYY`).
   - When a new patient registers or logs in, their protocol starts **completely clean (`items: []`)**. No default or random medicines are added automatically.

3. **Patient Deletion**:
   - Practitioners can delete individual patients via the Web Studio (`🗑️ Delete Patient` header button or roster trash icon) or via `DELETE /api/practitioner/delete-client/:clientId`.
   - Deleting a patient purges their profile, assigned protocol stack, and logged dose history.

4. **Expanded Supplement Timing Schedules**:
   - Comprehensive timing schedule options supported across backend, web modal, web filter chips, and iOS app:
     - 🌅 `Empty Stomach` (On Empty Stomach / Morning Wake-Up)
     - 🍳 `With Breakfast` (With Breakfast)
     - 🥗 `With Meal` (With Meals)
     - 🥪 `With Lunch` (With Lunch)
     - 🥩 `With Dinner` (With Dinner)
     - ☕ `Mid-Day` (Mid-Day / Afternoon)
     - 🏋️ `Pre-Workout` (Pre-Workout)
     - ⚡ `Post-Workout` (Post-Workout)
     - 🌙 `Before Bed` (Before Bed / Nighttime)

5. **App Login Screen Branding**:
   - `ClientLoginView.swift` circle logo displays bold text **`WB`** on a dark charcoal circular background.

6. **Practitioner Chat**:
   - Removed practitioner chat UI tabs and endpoints per user preference.

---

## 📡 4. Backend REST API Endpoints (`server.js`)

| Method | Endpoint | Description |
| :--- | :--- | :--- |
| `POST` | `/api/auth/register-client` | Registers a new patient with Name, DOB, Goal, Symptoms |
| `POST` | `/api/auth/login-client` | Authenticates patient with Name and DOB |
| `GET` | `/api/practitioner/clients` | Fetches full patient roster with adherence metrics & streak |
| `POST` | `/api/practitioner/reset` | Resets roster to 0 patients |
| `DELETE` | `/api/practitioner/delete-client/:clientId` | Deletes patient profile, protocol, and logs |
| `GET` | `/api/protocol/:clientId` | Returns prescribed protocol stack & practitioner note |
| `POST` | `/api/practitioner/assign-protocol/:clientId` | Prescribes/updates supplement items or guidance note |
| `DELETE` | `/api/practitioner/delete-protocol-item/:clientId/:itemId` | Removes prescribed supplement from patient protocol |
| `POST` | `/api/dose-log` | Records dose completion (`Done` or `Wait`) |
| `GET` | `/api/dose-log/:clientId` | Fetches dose logs for calculating adherence streak |

---

## 📂 5. Key Codebase Files Map

```
/Users/davidbondarescu/WellnessBuddy/
├── backend/
│   ├── server.js              # Node.js REST API & static server
│   ├── data.json              # File-backed JSON database
│   └── public/
│       └── index.html         # Responsive Web Studio & Patient Portal
├── WellnessBuddy/
│   ├── WellnessBuddyApp.swift # iOS App entry point & TabView container
│   ├── Models/
│   │   └── ProtocolModels.swift # Data models (ProtocolItem, TimingSchedule, etc.)
│   ├── Services/
│   │   ├── APIService.swift   # HTTP network client with multi-host fallback
│   │   ├── NotificationService.swift # Local push notifications for due doses
│   │   └── FullscriptService.swift   # Fullscript store catalog integration
│   ├── ViewModels/
│   │   └── WellnessBuddyViewModel.swift # App state & live auto-polling engine
│   └── Views/
│       ├── ClientLoginView.swift      # Client auth screen (default "Jhon Doe", WB logo)
│       ├── ClientDashboardView.swift  # Protocol dashboard, streak & reminder banners
│       ├── PractitionerDashboardView.swift # Practitioner studio in iOS app
│       ├── SupplementTrackerView.swift# Timing schedule breakdown view
│       ├── ComplianceStatsView.swift  # Adherence charts & progress metrics
│       ├── FullscriptPortalView.swift # Supplement ordering portal
│       └── PersistentReminderBannerView.swift # Pinned top reminder alert
├── generate_xcodeproj.py      # Python script to regenerate project.pbxproj
└── README.md                  # Project repository documentation
```

---

## 🚀 6. Developer Quick Commands

### Run Backend Locally
```bash
node backend/server.js
# Runs live at http://localhost:3000
```

### Open Web Studio
```bash
open http://localhost:3000
```

### Regenerate Xcode Project & Open App
```bash
python3 generate_xcodeproj.py
open WellnessBuddy.xcodeproj
```

### Sync & Push Updates to GitHub
```bash
git add .
git commit -m "Update codebase"
git push origin main
```
