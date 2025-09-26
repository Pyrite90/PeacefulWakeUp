//
//  CompatibilityLayer.swift
//  Peaceful Wake Up
//
//  Created by Mike McDonald on 9/25/25.
//

import SwiftUI
import AVFoundation
import MediaPlayer

// MARK: - iOS Version Compatibility
struct iOSCompatibility {
    static let current = ProcessInfo.processInfo.operatingSystemVersion
    
    static var isiOS18OrLater: Bool {
        return current.majorVersion >= 18
    }
    
    static var isiOS17OrLater: Bool {
        return current.majorVersion >= 17
    }
    
    static var isiOS16OrLater: Bool {
        return current.majorVersion >= 16
    }
    
    static var versionString: String {
        return "\(current.majorVersion).\(current.minorVersion).\(current.patchVersion)"
    }
    
    // Helper to determine if running on current iOS or later
    static func isVersion(_ version: Int, orLater: Bool = true) -> Bool {
        return orLater ? current.majorVersion >= version : current.majorVersion == version
    }
}

// MARK: - Audio Session Compatibility
extension AVAudioSession {
    func setCompatibleCategory() throws {
        if iOSCompatibility.isiOS18OrLater {
            // iOS 18+ enhanced audio categories
            try setCategory(.playback, mode: .default, options: [.allowBluetoothA2DP, .duckOthers])
        } else if iOSCompatibility.isiOS17OrLater {
            // iOS 17+ enhanced categories
            try setCategory(.playback, mode: .default, options: [.duckOthers, .allowBluetoothA2DP])
        } else {
            // iOS 16+ standard categories
            try setCategory(.playback, mode: .default, options: [.allowBluetoothA2DP])
        }
    }
}

// MARK: - Volume Control Compatibility
struct VolumeControlCompat {
    static func setSystemVolume(_ volume: Float) {
        // Use traditional MPVolumeView for all current iOS versions
        // This is the most reliable method across iOS 16-18+
        setVolumeLegacy(volume)
    }
    
    private static func setVolumeLegacy(_ volume: Float) {
        let safeVolume = min(max(volume, 0.0), 1.0)
        
        // Create a new volume view each time to avoid caching issues
        let volumeView = MPVolumeView(frame: .zero)
        volumeView.showsVolumeSlider = false
        
        // Add to a window briefly to ensure it's in the view hierarchy
        DispatchQueue.main.async {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first {
                window.addSubview(volumeView)
                
                // Find the volume slider with timeout protection
                var volumeSlider: UISlider?
                let startTime = CFAbsoluteTimeGetCurrent()
                
                for subview in volumeView.subviews {
                    if let slider = subview as? UISlider {
                        volumeSlider = slider
                        break
                    }
                    
                    // Prevent infinite loops - timeout after 0.1 seconds
                    if CFAbsoluteTimeGetCurrent() - startTime > 0.1 {
                        break
                    }
                }
                
                if let slider = volumeSlider {
                    slider.value = safeVolume
                }
                
                // Remove from view hierarchy
                volumeView.removeFromSuperview()
            }
        }
    }
}

// MARK: - Brightness Control Compatibility
struct BrightnessControlCompat {
    static func setBrightness(_ brightness: CGFloat) {
        let safeBrightness = min(max(brightness, 0.0), 1.0)
        
        // Use standard brightness control for all iOS versions
        setBrightnessLegacy(safeBrightness)
    }
    
    private static func setBrightnessLegacy(_ brightness: CGFloat) {
        DispatchQueue.main.async {
            guard UIScreen.main.responds(to: #selector(setter: UIScreen.brightness)) else {
                return
            }
            UIScreen.main.brightness = brightness
        }
    }
}

// MARK: - TimelineView Compatibility
struct TimelineViewCompat {
    static func createPeriodicSchedule(interval: TimeInterval) -> PeriodicTimelineSchedule {
        // Return concrete type instead of protocol to avoid Swift 6 warnings
        return PeriodicTimelineSchedule(from: Date(), by: interval)
    }
}

// MARK: - Animation Compatibility
struct AnimationCompat {
    static var easeInOut: Animation {
        if iOSCompatibility.isiOS18OrLater {
            // iOS 18+ enhanced animations - with proper availability check
            if #available(iOS 18.0, *) {
                return Animation.easeInOut(duration: 0.3)
            } else {
                return Animation.easeInOut(duration: 0.3)
            }
        }
        // iOS 16-17 standard animations
        return Animation.easeInOut(duration: 0.3)
    }
    
    static var spring: Animation {
        if iOSCompatibility.isiOS17OrLater {
            // Use proper Animation.spring syntax
            return Animation.spring(response: 0.5, dampingFraction: 0.7)
        } else {
            return Animation.easeInOut(duration: 0.3)
        }
    }
}

// MARK: - Background Task Compatibility
struct BackgroundTaskCompat {
    static func beginBackgroundTask(withName name: String, expirationHandler handler: @escaping () -> Void) -> UIBackgroundTaskIdentifier {
        // Background task API is the same across iOS versions
        return UIApplication.shared.beginBackgroundTask(withName: name, expirationHandler: handler)
    }
}

// MARK: - Feature Availability Checks
struct FeatureAvailability {
    /// Check if advanced audio features are available
    static var hasAdvancedAudioFeatures: Bool {
        return iOSCompatibility.isiOS17OrLater
    }
    
    /// Check if enhanced brightness control is available
    static var hasEnhancedBrightnessControl: Bool {
        return iOSCompatibility.isiOS18OrLater
    }
    
    /// Check if spatial audio is available
    static var hasSpatialAudio: Bool {
        return iOSCompatibility.isiOS18OrLater
    }
}

// MARK: - Deployment Target Configuration
#if swift(>=6.0)
// Swift 6+ protocol conformance
extension TimelineViewCompat {
    static func createOptimizedSchedule(interval: TimeInterval) -> some TimelineSchedule {
        return PeriodicTimelineSchedule(from: Date(), by: interval)
    }
}
#endif
