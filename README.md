# Peaceful Wake Up 🌅

A beautiful, gentle iOS alarm clock app that simulates a natural sunrise to wake you up peacefully. Built with SwiftUI and designed for a serene wake-up experience.

![Xcode](https://img.shields.io/badge/Xcode-007ACC?style=for-the-badge&logo=Xcode&logoColor=white)
![Swift](https://img.shields.io/badge/swift-F54A2A?style=for-the-badge&logo=swift&logoColor=white)
![iOS](https://img.shields.io/badge/iOS-000000?style=for-the-badge&logo=ios&logoColor=white)

## Features ✨

### 🌄 Sunrise Simulation
- **Natural Wake-Up**: Gradual brightness increase over 10 minutes before your alarm
- **System Brightness Control**: Automatically sets device brightness to maximum during sunrise phase
- **Visual Sunrise Effect**: Beautiful gradient background that transitions from deep orange to pale yellow

### 🔇 Silent Mode Override
- **Gentle Audio**: Starts with barely audible mockingbird sounds that gradually increase in volume
- **Volume Progression**: Audio increases from 10% to 100% over 3 minutes
- **Silent Alarm Option**: Choose to have a visual-only alarm without sound

### 💤 Smart Inactivity Features
- **Auto-Dimming**: Screen dims after 30 seconds of inactivity to save battery
- **Sunrise Protection**: Prevents dimming during the 10-minute sunrise phase
- **Touch to Wake**: Simple tap restores screen without affecting device brightness

### 🎯 Intuitive Interface
- **Clean Design**: Minimalist sunrise-themed interface
- **Large Time Display**: Easy-to-read clock with 24-hour format
- **Slide to Cancel**: Smooth slider interface to cancel active alarms
- **One-Touch Setup**: Simple alarm setting with time picker and silent option

## Screenshots 📱

*Screenshots coming soon...*

## Installation 🚀

### Requirements
- iOS 15.0+
- Xcode 14.0+
- Swift 5.0+

### Setup
1. Clone this repository:
   ```bash
   git clone https://github.com/Pyrite90/PeacefulWakeUp.git
   cd PeacefulWakeUp
   ```

2. Open the project in Xcode:
   ```bash
   open "Peaceful Wake Up.xcodeproj"
   ```

3. Build and run the project on your device or simulator

## Usage 💡

### Setting an Alarm
1. Tap "Set Alarm" button
2. Use the time picker to select your desired wake-up time
3. Optionally check "Silent alarm" for visual-only wake-up
4. Tap "Confirm Alarm" to activate

### During Sunrise Phase (10 minutes before alarm)
- Your device brightness automatically increases to maximum
- A beautiful sunrise gradient creates a gentle visual wake-up
- The screen stays active and bright throughout the sunrise

### When Alarm Goes Off
- **With Sound**: Gentle mockingbird audio starts quietly and gradually increases
- **Silent Mode**: Visual sunrise effect continues without audio
- **To Stop**: Slide the cancel slider to turn off the alarm

### Power Management
- The app prevents your device from sleeping during active alarms
- Inactivity dimming saves battery when you're not using the app
- All timers and brightness settings are restored when you exit the app

## Architecture 🏗️

The app follows a clean, modular SwiftUI architecture:

```
Peaceful Wake Up/
├── ContentView.swift          # Main app coordinator
├── Views/                     # UI Components
│   ├── SunriseBackgroundView.swift
│   ├── TimeDisplayView.swift
│   ├── AlarmSetterView.swift
│   ├── AlarmControlsView.swift
│   ├── SliderToCancelView.swift
│   └── BrightnessOverlayView.swift
├── Managers/                  # Business Logic
│   ├── AlarmManager.swift
│   └── BrightnessManager.swift
└── Sounds/
    └── Mockingbird.mp3       # Gentle wake-up sound
```

### Key Components

#### Views
- **SunriseBackgroundView**: Beautiful gradient background
- **TimeDisplayView**: Clock display with alarm information
- **AlarmSetterView**: Time picker and settings interface
- **AlarmControlsView**: Main action buttons and controls
- **SliderToCancelView**: Smooth slide-to-cancel interface
- **BrightnessOverlayView**: Manages screen dimming and brightness

#### Core Features
- **Secure Brightness Control**: Safe system brightness management
- **Audio Session Management**: Handles silent mode override and volume control
- **Background Task Support**: Maintains functionality when app goes to background
- **Timer Management**: Coordinated sunrise, volume, and inactivity timers

## Technical Highlights 🔧

### Brightness Management
- Captures original device brightness for restoration
- Implements safe brightness bounds checking
- Separates visual effects from system brightness control
- Prevents accidental brightness changes from touch events

### Audio System
- Secure audio session configuration with error handling
- File validation and size checking for audio resources
- Graceful fallback for audio permission issues
- Volume progression with precise timing control

### Memory & Performance
- Proper timer lifecycle management
- Background task coordination
- SwiftUI state management best practices
- Efficient view composition and reuse

## Contributing 🤝

Contributions are welcome! Please feel free to submit a Pull Request. For major changes, please open an issue first to discuss what you would like to change.

### Development Guidelines
- Follow Swift style guidelines
- Maintain the modular architecture
- Add appropriate comments for complex logic
- Test on both simulator and physical device
- Ensure proper cleanup of resources (timers, audio sessions)

## License 📄

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments 🙏

- Mockingbird sound effect for gentle wake-up audio
- SwiftUI community for inspiration and best practices
- Beta testers for feedback and suggestions

## Roadmap 🗺️

### Planned Features
- [ ] Multiple alarm support
- [ ] Custom sunrise duration settings
- [ ] Additional nature sounds
- [ ] Weekend/weekday alarm scheduling
- [ ] Gradual volume increase customization
- [ ] Apple Watch companion app
- [ ] Sleep tracking integration

### Technical Improvements
- [ ] Core Data persistence for alarm settings
- [ ] Push notification fallback
- [ ] Accessibility improvements
- [ ] iPad optimization
- [ ] Widget support

## Support 💬

If you encounter any issues or have questions:

1. Check the [Issues](https://github.com/Pyrite90/PeacefulWakeUp/issues) page
2. Create a new issue if your problem isn't already reported
3. Provide detailed information about your device and iOS version

## Version History 📋

### v1.0.0 (Current)
- Initial release
- Core sunrise simulation functionality
- Silent mode override
- Slide-to-cancel interface
- Smart inactivity management

---

**Made with ❤️ for peaceful mornings**

*Wake up gently, start your day right* ☀️
