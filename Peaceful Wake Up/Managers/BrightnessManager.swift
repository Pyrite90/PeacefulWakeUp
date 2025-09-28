//
//  BrightnessManager.swift
//  Peaceful Wake Up
//
//  Created by Mike McDonald on 9/11/25.
//

import Foundation
import SwiftUI
#if os(iOS)
import UIKit

@Observable
class BrightnessManager: BrightnessManaging {
    // MARK: - Properties
    var currentBrightness: CGFloat = 1.0
    var showBlackOverlay: Bool = false
    
    // iOS 26 ready: Initialize safely without UIScreen.main
    private var originalBrightness: CGFloat = 1.0
    var systemBrightnessAtSunriseStart: CGFloat = 1.0
    var brightnessBeforeInactivity: CGFloat = 1.0
    private var lastInteraction: Date = Date()
    // inactivityTimer removed - handled by InactivityTimelineView
    

    
    // MARK: - Public Methods
    func setupBrightness() {
        // iOS 26 ready: Handle UIScreen.main deprecation gracefully
        if iOSCompatibility.isiOS26OrLater {
            originalBrightness = 1.0
        } else {
            originalBrightness = UIScreen.main.brightness
        }
        setBrightnessSafely(1.0)
        currentBrightness = 1.0
        // Inactivity handling is managed by InactivityTimelineView
    }
    
    func cleanup() {
        setBrightnessSafely(originalBrightness)
        // Inactivity timer cleanup is managed by InactivityTimelineView
    }
    
    func userInteracted() {
        lastInteraction = Date()
        
        let shouldRestoreBrightness = showBlackOverlay || currentBrightness < 1.0
        
        if showBlackOverlay {
            withAnimation(.easeInOut(duration: 0.3)) {
                showBlackOverlay = false
            }
        }
        
        if shouldRestoreBrightness {
            setBrightnessSafely(1.0)
            currentBrightness = 1.0
        }
    }
    
    func startSunrisePhase() {
        if iOSCompatibility.isiOS26OrLater {
            systemBrightnessAtSunriseStart = 1.0
        } else {
            systemBrightnessAtSunriseStart = UIScreen.main.brightness
        }
        setBrightnessSafely(1.0)
    }
    
    func updateSunriseProgress(alarmTime: Date) {
        let now = Date()
        let sunriseStart = alarmTime.addingTimeInterval(-600) // 10 minutes before alarm
        
        guard now >= sunriseStart && now <= alarmTime else { return }
        
        let progress = now.timeIntervalSince(sunriseStart) / 600.0
        let targetBrightness = max(0.0, min(1.0, progress))
        
        currentBrightness = CGFloat(targetBrightness)
    }
    
    func completeSunrise() {
        setBrightnessSafely(1.0)
        currentBrightness = 1.0
    }
    
    func restoreBrightness() {
        setBrightnessSafely(systemBrightnessAtSunriseStart)
        currentBrightness = 1.0
    }
    
    // MARK: - Private Methods
    func setBrightnessSafely(_ brightness: CGFloat) {
        let safeBrightness = min(max(brightness, 0.0), 1.0)
        
        if iOSCompatibility.isiOS26OrLater {
            // iOS 26+ uses windowScene.screen when available or visual overlay
            print("iOS 26+ brightness control via visual overlay")
        } else {
            guard UIScreen.main.responds(to: #selector(setter: UIScreen.brightness)) else {
                print("Brightness control not available")
                return
            }
            UIScreen.main.brightness = safeBrightness
        }
    }
    
    // Inactivity timer functionality moved to InactivityTimelineView to prevent conflicts
}

#endif // os(iOS)