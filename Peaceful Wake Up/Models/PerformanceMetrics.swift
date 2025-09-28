//
//  PerformanceMetrics.swift
//  Peaceful Wake Up
//
//  Created by Mike McDonald on 9/26/25.
//

import Foundation

// MARK: - Performance Monitoring
@MainActor
class PerformanceMetrics: ObservableObject {
    static let shared = PerformanceMetrics()
    
    @Published private(set) var audioSetupTime: TimeInterval = 0
    @Published private(set) var brightnessChangeCount: Int = 0
    @Published private(set) var volumeChangeCount: Int = 0
    
    // Performance monitoring properties
    @Published private(set) var currentFPS: Double = 60.0
    @Published private(set) var memoryUsageMB: Double = 0.0
    @Published private(set) var cpuUsage: Double = 0.0
    
    func recordAudioSetupTime(_ time: TimeInterval) {
        audioSetupTime = time
    }
    
    func recordBrightnessChange() {
        brightnessChangeCount += 1
    }
    
    func recordVolumeChange() {
        volumeChangeCount += 1
    }
    
    func updatePerformanceMetrics() {
        // Simple mock values for performance monitoring
        // In a real app, these would be calculated from actual system metrics
        currentFPS = Double.random(in: 55.0...60.0)
        memoryUsageMB = Double.random(in: 50.0...150.0)
        cpuUsage = Double.random(in: 5.0...25.0)
    }
    
    func logMetrics() {
        print("Performance Metrics:")
        print("  Audio Setup Time: \(audioSetupTime)s")
        print("  Brightness Changes: \(brightnessChangeCount)")
        print("  Volume Changes: \(volumeChangeCount)")
        print("  Current FPS: \(currentFPS)")
        print("  Memory Usage: \(memoryUsageMB)MB")
        print("  CPU Usage: \(cpuUsage)%")
    }
}
