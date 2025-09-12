//
//  AlarmManager.swift
//  Peaceful Wake Up
//
//  Created by Mike McDonald on 9/11/25.
//

import Foundation
import SwiftUI
import AVFoundation

@Observable
class AlarmManager {
    // MARK: - Properties
    var alarmTime: Date = Date().addingTimeInterval(3600)
    var isAlarmSet: Bool = false
    var isSilentAlarm: Bool = false
    var alarmStartTime: Date?
    var hasEnteredSunrisePhase: Bool = false
    
    // Timers
    private var sunriseTimer: Timer?
    private var volumeTimer: Timer?
    
    // Audio
    private var audioPlayer: AVAudioPlayer?
    private var originalVolume: Float = 0.0
    
    // MARK: - Computed Properties
    var timeUntilAlarm: String {
        guard isAlarmSet else { return "" }
        
        let timeInterval = alarmTime.timeIntervalSince(Date())
        
        // If alarm time has passed, show that it's active
        guard timeInterval > 0 else { return "Alarm Active" }
        
        let hours = Int(timeInterval) / 3600
        let minutes = Int(timeInterval.truncatingRemainder(dividingBy: 3600)) / 60
        
        if hours > 0 {
            return "\(hours) Hours \(minutes) Minutes"
        } else {
            return "\(minutes) Minutes"
        }
    }
    
    // MARK: - Public Methods
    func setAlarm() {
        // Remove seconds and nanoseconds from the selected alarm time
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: alarmTime)
        guard let exactTime = calendar.date(from: components) else {
            print("Failed to create exact alarm time - invalid date components")
            return
        }
        
        // Validate alarm time is reasonable (not too far in future)
        let maxFutureTime = Date().addingTimeInterval(7 * 24 * 3600) // 7 days
        guard exactTime <= maxFutureTime else {
            print("Alarm time too far in future - maximum 7 days allowed")
            return
        }
        
        // Validate alarm time is not in the past by more than a few minutes
        let minimumValidTime = Date().addingTimeInterval(-300) // Allow 5 minutes in past for clock sync issues
        guard exactTime > minimumValidTime else {
            print("Alarm time too far in the past")
            return
        }
        
        alarmTime = exactTime
        
        // Adjust to tomorrow if needed
        if alarmTime <= Date() {
            guard let tomorrowTime = Calendar.current.date(byAdding: .day, value: 1, to: alarmTime) else {
                print("Failed to calculate tomorrow's alarm time")
                return
            }
            alarmTime = tomorrowTime
        }
        
        isAlarmSet = true
        hasEnteredSunrisePhase = false
        startSunriseTimer()
    }
    
    func cancelAlarm() {
        isAlarmSet = false
        hasEnteredSunrisePhase = false
        invalidateTimers()
        stopAlarmSound()
    }
    
    func startSunrisePhase(brightnessManager: BrightnessManager) {
        guard !hasEnteredSunrisePhase else { return }
        
        hasEnteredSunrisePhase = true
        brightnessManager.startSunrisePhase()
        print("Sunrise phase started - system brightness set to maximum")
    }
    
    func completeAlarm() {
        guard !isSilentAlarm else { return }
        
        // Record the time when alarm sound starts
        alarmStartTime = Date()
        
        // Play alarm sound at lowest volume and keep it looping
        playAlarmSound()
    }
    
    // MARK: - Private Methods
    private func startSunriseTimer() {
        sunriseTimer?.invalidate()
        sunriseTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { _ in
            let now = Date()
            let sunriseStart = self.alarmTime.addingTimeInterval(-600) // 10 minutes before alarm
            
            if now >= sunriseStart && now <= self.alarmTime {
                // Will be handled by ContentView's brightness manager
            } else if now > self.alarmTime {
                self.completeAlarm()
            }
        }
    }
    
    private func invalidateTimers() {
        sunriseTimer?.invalidate()
        volumeTimer?.invalidate()
        sunriseTimer = nil
        volumeTimer = nil
    }
    
    private func setupAudioPlayer() {
        guard let soundURL = Bundle.main.url(forResource: "Mockingbird", withExtension: "mp3") else {
            print("Could not find Mockingbird.mp3 file")
            return
        }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
            audioPlayer?.numberOfLoops = -1 // Loop indefinitely
            audioPlayer?.volume = 0.1
            _ = audioPlayer?.prepareToPlay()
        } catch {
            print("Failed to initialize audio player: \(error.localizedDescription)")
            audioPlayer = nil
        }
    }
    
    private func playAlarmSound() {
        if audioPlayer == nil {
            setupAudioPlayer()
        }
        
        guard let player = audioPlayer else {
            print("Audio player not available")
            return
        }
        
        // Override silent mode
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .default, options: [])
            try audioSession.setActive(true)
            
            let playResult = player.play()
            if playResult {
                startVolumeTimer()
            }
        } catch {
            print("Failed to play alarm sound: \(error.localizedDescription)")
        }
    }
    
    private func stopAlarmSound() {
        audioPlayer?.stop()
        volumeTimer?.invalidate()
        volumeTimer = nil
    }
    
    private func startVolumeTimer() {
        volumeTimer?.invalidate()
        volumeTimer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { _ in
            self.increaseVolume()
        }
    }
    
    private func increaseVolume() {
        guard let startTime = alarmStartTime else { return }
        
        let timeElapsed = Date().timeIntervalSince(startTime)
        
        // Stop increasing volume after 3 minutes (180 seconds)
        guard timeElapsed <= 180 else {
            volumeTimer?.invalidate()
            volumeTimer = nil
            return
        }
        
        let intervalsElapsed = timeElapsed / 10.0
        let targetVolume = min(1.0, 0.1 + (intervalsElapsed * 0.05))
        
        audioPlayer?.volume = Float(targetVolume)
    }
}