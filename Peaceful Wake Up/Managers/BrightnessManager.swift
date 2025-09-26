//
//  BrightnessManager.swift
//  Peaceful Wake Up
//
//  Created by Mike McDonald on 9/11/25.
//

import Foundation
import SwiftUI

@Observable
class BrightnessManager: BrightnessManaging {
    // MARK: - Properties
    var currentBrightness: CGFloat = 1.0
    var showBlackOverlay: Bool = false
    
    private var originalBrightness: CGFloat = UIScreen.main.brightness
    private var systemBrightnessAtSunriseStart: CGFloat = 1.0
    private var brightnessBeforeInactivity: CGFloat = 1.0
    private var lastInteraction: Date = Date()
    private var inactivityTimer: Timer?
    
    // MARK: - Public Methods
    func setupBrightness() {
        originalBrightness = UIScreen.main.brightness
        setBrightnessSafely(1.0)
        currentBrightness = 1.0
        startInactivityTimer()
    }
    
    func cleanupBrightness() {
        setBrightnessSafely(originalBrightness)
        inactivityTimer?.invalidate()
        inactivityTimer = nil
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
        systemBrightnessAtSunriseStart = UIScreen.main.brightness
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
    private func setBrightnessSafely(_ brightness: CGFloat) {
        let safeBrightness = min(max(brightness, 0.0), 1.0)
        
        guard UIScreen.main.responds(to: #selector(setter: UIScreen.brightness)) else {
            print("Brightness control not available")
            return
        }
        
        UIScreen.main.brightness = safeBrightness
    }
    
    private func startInactivityTimer() {
        inactivityTimer?.invalidate()
        inactivityTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            let timeSinceLastInteraction = Date().timeIntervalSince(self.lastInteraction)
            let shouldShowOverlay = timeSinceLastInteraction > 30
            
            if shouldShowOverlay != self.showBlackOverlay {
                DispatchQueue.main.async {
                    if shouldShowOverlay {
                        self.brightnessBeforeInactivity = UIScreen.main.brightness
                        self.setBrightnessSafely(0.01)
                        self.currentBrightness = 0.01
                    }
                    
                    withAnimation(.easeInOut(duration: 0.3)) {
                        self.showBlackOverlay = shouldShowOverlay
                    }
                }
            }
        }
    }
}