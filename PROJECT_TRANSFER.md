# 🌿 Wellness Buddy — Complete Project Transfer & Handoff Document

> **System Overview**: Wellness Buddy is an end-to-end integrative wellness platform and supplement reminder system for health practitioners and clients. It connects a Node.js backend server (deployed live on Render), a responsive web studio/portal, and a native SwiftUI iOS app.

---

## 📍 1. Key Repository & Environment Details

- **GitHub Repository**: [`https://github.com/davidc-alt/wellness-buddy-.git`](https://github.com/davidc-alt/wellness-buddy-.git) (`main` branch)
- **Local Working Directory**: `/Users/davidbondarescu/WellnessBuddy`
- **Live Deployed Web Application**: [`https://wellness-buddy-vduz.onrender.com`](https://wellness-buddy-vduz.onrender.com)
- **Backend Entry File**: `backend/server.js` (runs live on `http://localhost:3000` & Render)
- **Web Frontend**: `backend/public/index.html` (Web Studio & Patient Portal)
- **iOS Application**: `WellnessBuddy/` (SwiftUI iOS app targeting iOS 16+)
- **Xcode Generator Script**: `python3 generate_xcodeproj.py`

---

## 🎨 2. Design System & Palette

- **Sage Muted**: `#5C8B7D` (`Color.paletteSage`)
- **Deep Ocean Slate**: `#2F6B87` (`Color.paletteOcean`)
- **Cool Muted Silver**: `#A7B0B4` (`Color.paletteSilver`)
- **Soft Light Grey Background**: `#EDEFF0` (`Color.paletteSoftBg`)
- **Dark Charcoal Accent**: `#354047` (`Color.paletteDark`)
- **Card Aesthetics**: 24pt rounded pure white minimalist cards with subtle elevation (`.calmCardStyle`).

---

## ⚙️ 3. Key Business Rules & Enforced System Behaviors

1. **Practitioner Identity & Fullscript Integration**:
   - Primary practitioner name is **`Practitioner Luba Vitti`** / **`Dr. Luba Vitti Integrative Health`** across all backend API responses, web views, and iOS app displays.
   - Fullscript dispensary URL code: `https://fullscript.com/dispensary/dr-luba-vitti`.

2. **Persistent App Login & Multi-User Support**:
   - Session data is persisted in `UserDefaults` (`wb_is_logged_in`, `wb_active_client_id`, `wb_active_client_name`, `wb_active_client_dob`, `wb_active_client_goal`).
   - Closing and reopening the app automatically restores the user's login state and live protocols without asking for credentials again.
   - Each mobile device stores its own local `UserDefaults` session, allowing concurrent logins across different phones connecting to the live backend server.

3. **Clean Initial Login Inputs**:
   - Input fields in `ClientLoginView.swift` and `index.html` start completely empty (`""`) with dynamic placeholders (`Last Name First Name` and `MM-DD-YYYY`) that disappear instantly as soon as the user enters their first letter.

4. **Clean Protocol Defaults**:
   - New patients start with a completely empty protocol (`items: []`). Never auto-add random supplements.

5. **"Done" Pill Micro-Animation**:
   - Tapping "Done" on any pill card triggers a 360° checkmark seal rotation, particle sparkle explosion, scale pulse, and tactile haptic feedback (`PillDoneAnimationButton`).

6. **Dynamic Consecutive-Day Streak Counter**:
   - Dynamic streak calculation (`currentStreakDays` in `WellnessBuddyViewModel.swift`) counts actual consecutive calendar days with completed doses fetched live from backend `/api/dose-log/:clientId`.

7. **Live Backend Heartbeat & Auto-Sync**:
   - `server.js` runs a self-ping heartbeat loop (`/api/ping`) every 8 minutes to prevent Render free-tier cold-start container resets.
   - `APIService.swift` connects directly to `https://wellness-buddy-vduz.onrender.com` with a 30s timeout and automatic background retry loop.
   - `index.html` features a `🟢 LIVE SYNC ACTIVE` status badge and an instant `visibilitychange` window focus auto-sync listener.

8. **Expanded Supplement Timing Schedules**:
   - 🌅 `Empty Stomach` (On Empty Stomach / Morning Wake-Up)
   - 🍳 `With Breakfast` (With Breakfast)
   - 🥗 `With Meal` (With Meals)
   - 🥪 `With Lunch` (With Lunch)
   - 🥩 `With Dinner` (With Dinner)
   - ☕ `Mid-Day` (Mid-Day / Afternoon)
   - 🏋️ `Pre-Workout` (Pre-Workout)
   - ⚡ `Post-Workout` (Post-Workout)
   - 🌙 `Before Bed` (Before Bed / Nighttime)

9. **App Login Branding**:
   - `ClientLoginView.swift` displays circle logo with bold text **`WB`**.

10. **Web Patient Portal Testing Badge**:
    - Patient Login tab on the web portal features a prominent `⚠️ FOR TESTING PURPOSES ONLY` badge.

---

## 📡 4. Core Backend REST API Endpoints (`server.js`)

| Method | Endpoint | Description |
| :--- | :--- | :--- |
| `GET` | `/api/ping` | Live health check & keep-alive ping |
| `POST` | `/api/auth/register-client` | Registers a new patient with Name, DOB, Goal |
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
│   ├── server.js              # Node.js REST API & heartbeat server
│   ├── data.json              # File-backed JSON database
│   └── public/
│       └── index.html         # Responsive Web Studio & Patient Portal (Live Sync Active)
├── WellnessBuddy/
│   ├── WellnessBuddyApp.swift # iOS App entry point & TabView container
│   ├── Info.plist             # App configuration & ATS permissions
│   ├── Models/
│   │   └── ProtocolModels.swift # Data models (ProtocolItem, TimingSchedule, DoseLogEntry, etc.)
│   ├── Services/
│   │   ├── APIService.swift   # Live HTTP network client with 30s timeout & retry engine
│   │   ├── NotificationService.swift # Local push notifications for due doses
│   │   └── FullscriptService.swift   # Fullscript store integration for Dr. Luba Vitti
│   ├── ViewModels/
│   │   └── WellnessBuddyViewModel.swift # App state, UserDefaults persistence & live auto-polling
│   └── Views/
│       ├── ClientLoginView.swift      # Client auth screen (WB logo, clean placeholders)
│       ├── ClientDashboardView.swift  # Protocol dashboard, streak & PillDoneAnimationButton
│       ├── PractitionerDashboardView.swift # Practitioner studio in iOS app
│       ├── SupplementTrackerView.swift# Timing schedule breakdown view
│       ├── ComplianceStatsView.swift  # Live adherence charts & 7-day progress grid
│       ├── FullscriptPortalView.swift # Dr. Luba Vitti Fullscript dispensary portal
│       └── PersistentReminderBannerView.swift # Pinned top reminder alert
├── generate_xcodeproj.py      # Python script to regenerate project.pbxproj
├── PROJECT_TRANSFER.md        # Project handoff documentation
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
git commit -m "Update handoff documentation"
git push origin main
```
