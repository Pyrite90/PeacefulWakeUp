//
//  Configuration.swift
//  Peaceful Wake Up
//
//  Created by Mike McDonald on 9/26/25.
//

import Foundation

// MARK: - App Configuration
struct AppConfiguration {
    // MARK: - Audio Settings
    struct Audio {
        static let defaultVolume: Float = 0.1
        static let maxVolumeIncrement: Float = 0.2
        static let volumeIncreaseInterval: TimeInterval = 20.0
        static let maxAudioFileSize: Int = 50 * 1024 * 1024 // 50MB
        static let audioFileName = "Mockingbird"
        static let audioFileExtension = "mp3"
    }
    
    // MARK: - Brightness Settings
    struct Brightness {
        static let minimumBrightness: CGFloat = 0.01
        static let maximumBrightness: CGFloat = 1.0
        static let defaultBrightness: CGFloat = 1.0
        static let brightnessChangeThreshold: CGFloat = 0.01
        static let sunriseStartOffset: TimeInterval = -600 // 10 minutes before alarm
    }
    
    // MARK: - UI Settings
    struct UI {
        static let inactivityTimeout: TimeInterval = 30.0
        static let animationDuration: TimeInterval = 0.3
        static let timelineUpdateInterval: TimeInterval = 1.0
        static let performanceLoggingEnabled = true
    }
    
    // MARK: - Background Tasks
    struct BackgroundTask {
        static let taskName = "AlarmTimer"
        static let maxBackgroundTime: TimeInterval = 30.0 // iOS limit
    }
    
    // MARK: - Performance Monitoring
    struct Performance {
        static let maxAudioSetupTime: TimeInterval = 5.0
        static let maxBrightnessChangesPerMinute = 60
        static let maxVolumeChangesPerMinute = 60
        static let metricsLogInterval: TimeInterval = 300.0 // 5 minutes
    }
    
    // MARK: - Error Handling
    struct ErrorHandling {
        static let maxRetryAttempts = 3
        static let retryDelay: TimeInterval = 1.0
        static let errorReportingEnabled = true
    }
    
    // MARK: - Development/Debug Settings
    struct Debug {
        static let verboseLogging = false
        static let simulateErrors = false
        static let skipAudioSetup = false
        
        #if DEBUG
        static let showDebugInfo = true
        static let enablePerformanceTesting = true
        #else
        static let showDebugInfo = false
        static let enablePerformanceTesting = false
        #endif
    }
    
    // MARK: - Feature Flags
    struct Features {
        static let enableVolumeGradualIncrease = true
        static let enableSunriseEffect = true
        static let enablePerformanceMetrics = true
        static let enableBackgroundTasks = true
        static let enableAdvancedAudio = FeatureAvailability.hasAdvancedAudioFeatures
        static let enableEnhancedBrightness = FeatureAvailability.hasEnhancedBrightnessControl
    }
    
    // MARK: - Validation
    static func validateConfiguration() -> [String] {
        var issues: [String] = []
        
        // Validate audio settings
        if Audio.defaultVolume < 0 || Audio.defaultVolume > 1 {
            issues.append("Invalid default volume: \(Audio.defaultVolume)")
        }
        
        // Validate brightness settings
        if Brightness.minimumBrightness < 0 || Brightness.maximumBrightness > 1 {
            issues.append("Invalid brightness range")
        }
        
        // Validate timeouts
        if UI.inactivityTimeout <= 0 {
            issues.append("Invalid inactivity timeout")
        }
        
        return issues
    }
}
