<div align="center">
   <img src="assets\images\Rocket_GPS_logo.png" width="150px" alt="Project Logo" />
    <h1>Rocket GPS</h1>
</div>

## Description

Rocket GPS is a mobile application designed for model rocket tracking and recovery. The app connects to Bluetooth classic enabled device that provides NMEA GPS data, providing real-time tracking, position history, and recovery assistance.

Key capabilities:
- Real-time GPS tracking with altitude, position, and vertical velocity data
- Rocket bearing indicator with integrated compass
- Position history logging and KML export for Google Earth visualization
- Snapshot feature to save rocket positions for later recovery
- Bluetooth connectivity for GPS module integration

Built with Flutter for modern Android devices. It was designed for visualization of EggTimer Rocketry's Eggfinder TX/Mini Transmitter and Eggfinder RX “Dongle” Receiver with the bluetooth adapter. It will work with any other device that transmits NMEA data that contains the `$GPGGA` string


## Features

- **Real-time Tracking**: Monitor your rocket's position, altitude, and velocity in real-time via Bluetooth GPS module connection.
- **Recovery Assistant**: Built-in compass and bearing indicators help guide you to your rocket's location.
- **Data Export**: Save flight paths as KML files for detailed analysis in Google Earth.
- **Position Memory**: Save rocket positions as snapshots for recovery after app restarts.
- **Bluetooth Integration**: Easy connection to compatible GPS modules with status monitoring.

## Prerequisites

- Android device (minimum SDK 21 / Android version 5.0)
- Bluetooth Classic enabled GPS receiver
- Compatible GPS transmitter (e.g., Eggfinder TX/Mini)

## Installation

1. Clone the repository
```Bash
git clone https://github.com/wiltomdus/RocketGPS.git
cd RocketGPS
```
2. Install dependencies
```Bash
# Install the apk/appbundle on the connected device
flutter pub get
```
3. Build and install
```Bash 
flutter build apk --flavor openSource --release
flutter install
```

## Usage

### Getting Started
1. Pair the bluetooth device (Usualy called BT04-A)
2. Launch the Rocket GPS app
3. Press the "Connect" button to connect to the GPS modules

### Main Features

**Real-time Tracking**
- Current phone and GPS module position  displayed at top of screen
- Altitude and velocity shown in data cards
- Last update time indicates data freshness

**Recovery Assistant**
- Rocket bearing shown with arrow indicator
- Compass displays true north orientation
- Follow bearing arrow to locate rocket

**Data Management**
- View Map: Tap map icon to see position on map
- Export KML: Tap export icon to save flight path
- Save Position: Tap save icon to store current location
- Clear Data: Tap delete icon to remove saved position

## Development

### Available Flavors
- openSource: Community version
- playStore: Google Play Store version

### Build Commands
```bash
# Run specific flavor
flutter run --flavor openSource
flutter run --flavor playStore

# Debug builds
flutter build apk --flavor openSource --debug
flutter build apk --flavor playStore --debug

# Release builds
flutter build apk --flavor openSource --release
flutter build apk --flavor playStore --release

# Build app bundles (Play Store)
flutter build appbundle --flavor playStore --release

# Clean and rebuild
flutter clean
flutter pub get
flutter build apk --flavor playStore --release
```

### Debug vs Release Builds

**Debug builds** include developer tools, logging, assertions, and debugging symbols. They are larger in size but useful during development for debugging and testing.

**Release builds** are optimized for performance and size:
- Code is compiled with full optimizations
- Debugging symbols are removed
- Assets are compressed
- ProGuard rules are applied (Android)
- Suitable for distribution to end users

## Contributing
1. Fork the repository
2. Create feature branch
3. Commit changes
4. Open pull request

## Support
1. Open an issue
2. Feature requests
3. Discussions

## Roadmap

This project will be updated as needed if bugs or new features are needed. If you want a new feature and/or support for bluetooth low energy devices, feel free to create an issue and I will look into it.

## License

This project is licensed under the [GNU Affero General Public License v3.0](LICENSE). See the `LICENSE` file for more details on terms and conditions.

Feel free to use and contribute to the project under these terms!