# Pollution Tracker

A native macOS Menu Bar application that tracks real-time air pollution levels (AQI) for your current location using the Open-Meteo API.

## Features
- **Real-time AQI Tracking**: Uses Open-Meteo Air Quality API to fetch live pollution data.
- **Location Based**: Automatically detects your current location to provide accurate data.
- **Menu Bar Integration**: Quick glanceable AQI scale in the menu bar.
- **Detailed Popover**: Click to view detailed metrics, city name, and a 24-hour forecast chart.
- **Native Look & Feel**: Designed to match the aesthetics of macOS native widgets.

## Installation

1.  **Download**: Go to the [Releases page](https://github.com/macjul003/PollutionTracker/releases) and download the latest `PollutionTracker.zip`.
2.  **Unzip**: Extract the zip file.
3.  **Remove quarantine**: Open Terminal, navigate to where you unzipped the app, and run:
    ```
    xattr -cr PollutionTracker.app
    ```
    This is required because the app is not signed with an Apple Developer certificate. macOS quarantines apps downloaded from the internet and will show a "damaged" error without this step.
4.  **Open**: Double-click `PollutionTracker.app` to launch. The app will prompt you to move it to your Applications folder.

## Usage
- The app runs in the menu bar.
- The icon color changes based on the current Air Quality Index (Good, Fair, Poor, etc.).
- Click the icon to see detailed pollution information and a forecast chart.
- Use the "Quit" button in the popover to exit the application.

## Development

To build from source:
```bash
git clone https://github.com/macjul003/PollutionTracker.git
cd PollutionTracker
swift build -c release
```
