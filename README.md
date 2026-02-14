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
2.  **Unzip**: Extract the zip file to verify the `PollutionTracker.app`.
3.  **Move to Applications**: Drag and drop `PollutionTracker.app` into your `/Applications` folder.
4.  **Open**: 
    *   Right-click (or Control-click) on the app and select **Open**.
    *   Click **Open** in the dialog box (this is required because the app is not notarized).

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
