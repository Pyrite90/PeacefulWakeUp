//
//  PerformanceMetrics.swift
//  Peaceful Wake Up
//
//  Created by Mike McDonald on 9/26/25.
//

import Foundation

// MARK: - Performance Monitoring
class PerformanceMetrics: ObservableObject {
    @Published private(set) var audioSetupTime: TimeInterval = 0
    @Published private(set) var brightnessChangeCount: Int = 0
    @Published private(set) var volumeChangeCount: Int = 0
    
    func recordAudioSetupTime(_ time: TimeInterval) {
        audioSetupTime = time
    }
    
    func recordBrightnessChange() {
        brightnessChangeCount += 1
    }
    
    func recordVolumeChange() {
        volumeChangeCount += 1
    }
    
    func logMetrics() {
        print("Performance Metrics:")
        print("  Audio Setup Time: \(audioSetupTime)s")
        print("  Brightness Changes: \(brightnessChangeCount)")
        print("  Volume Changes: \(volumeChangeCount)")
    }
}
