# Gliding Compman — UI Description
## Overview
Gliding Compman is a mobile-first Android application designed for glider pilots to manage competition files and download essential flight computer data. The app features a sky blue aviation-themed interface optimized for mobile devices.
## Core Purpose
Enable pilots to quickly access and download task files, airspace files, and waypoint files for their selected gliding competitions.
## General Requirements
### Network Operations
- Every operation that fetches a remote resource (competition list, task file, airspace file, waypoint file) must show a visual loading indicator for its duration.
- Failures are handled uniformly across the app:
- An error message is displayed describing what went wrong (e.g. "Failed to load competitions", "Download failed").
- No operation fails silently.
- When the device is offline, a distinct "No internet connection" message is shown instead of a generic error. The Retry button becomes active once connectivity is restored.
### Destructive Actions
- Removing a competition from the home screen requires a confirmation dialog (e.g. "Remove [Competition Name]?") to prevent accidental deletion.
### Downloads
- Download buttons are disabled while a download is in progress to prevent duplicate concurrent downloads.
- Each download button reflects whether a file has previously been downloaded: a checkmark or "Downloaded" label is shown for files already present, distinct from the first-time state.
- The target download directory (e.g. the XCSoar data folder) is indicated on the Competition Detail screen so pilots can verify files are in the expected location.
## User Flow
### 1. Your Competitions (Home Screen)
- **Initial State:** Empty state with large "Add Competition" button
- **With Data:** Displays user's selected competitions as a scrollable list
- **Features:**
- Competition cards showing title, location, and dates
- Status badges: "Live" (green), "Upcoming" (blue), or "Past" (gray)
- Quick remove button (trash icon) on each card with confirmation dialog before removal
- Tap card to view competition details
- "Add" button in header to add more competitions
- Pull-to-refresh triggers a background check for updates across all saved competitions
### 2. Add Competition Screen
- **Search functionality:** Filter through ~50 competitions
- **Empty search state:** Displays a "No competitions found" message when the search query matches nothing
- **Selection interface:** Checkbox-based multi-select
- **Competition information displayed:**
- Title
- Location (with pin icon)
- Date range (formatted as "MMM d - MMM d, yyyy")
- Status badge (Live/Upcoming/Past)
- **Actions:**
- "Back" button to return without saving
- "Done" button to confirm selections
- Tap competitions to toggle selection (visual feedback with blue border and checkmark)
### 3. Competition Detail Screen
- **Header section:**
- Competition title
- Location with pin icon
- Date range with calendar icon
- Status badge
- **Download section:** Three prominent action buttons
- **Download Task:**
- Shows the task file version (e.g. "v3" or a date/hash identifier)
- Shows a **"New"** badge when an updated task file is detected since the last download
- On tap: downloads and installs the task; shows a confirmation message "XCSoar task installed"
- **Download Airspace:**
- Shows the filename of the airspace file (e.g. `germany_2026.txt`)
- Shows a **"New"** badge when an updated airspace file is detected since the last download
- **Download Waypoints:**
- Shows the filename of the waypoint file (e.g. `waypoints_2026.cup`)
- Shows a **"New"** badge when an updated waypoint file is detected since the last download
- **Last checked timestamp:** Displays when competition data was last refreshed (e.g. "Last checked: today at 14:32") so pilots know how current the "New" badges are.
- **Visual feedback:** Animated loading states on button press with checkmark on completion
- **Navigation:** Back button to return to home
### 4. About Screen
- Displays the app version number
- Credits the data source (SoaringSpot)
- Accessible from the home screen header menu
