//
//  AudioManager.swift
//  Peaceful Wake Up
//
//  Created by Mike McDonald on 9/26/25.
//

import AVFoundation
import MediaPlayer
import Foundation

// MARK: - Audio Management
class AudioManager: AudioManaging, ObservableObject {
    private var audioPlayer: AVAudioPlayer?
    private var originalVolume: Float = 0.0
    private var lastVolumeSet: Float?
    private var notificationObservers: [NSObjectProtocol] = []
    private var retryCount = 0
    private let maxRetries = AppConfiguration.ErrorHandling.maxRetryAttempts
    
    // MARK: - Audio Session Setup
    func setupAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            // Check if audio session is available and not being used by other apps
            guard !audioSession.isOtherAudioPlaying else {
                print("Other audio is playing - audio setup skipped")
                return
            }
            // Use compatibility layer for cross-version audio session setup
            try audioSession.setCompatibleCategory()
            try audioSession.setActive(true)
            // Store original volume safely
            originalVolume = audioSession.outputVolume
            // Prepare audio player with validation
            setupAudioPlayerSecurely()
            // Register for audio interruptions
            setupAudioInterruptionHandling()
        } catch let error as NSError {
            print("Failed to set up audio session: \(error.localizedDescription)")
            if error.code == AVAudioSession.ErrorCode.cannotStartPlaying.rawValue {
                print("Cannot start playing audio - permission denied or hardware issue")
            }
        } catch {
            print("Unexpected audio session error: \(error.localizedDescription)")
        }
    }
    
    private func setupAudioInterruptionHandling() {
        let observer = NotificationCenter.default.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: AVAudioSession.sharedInstance(),
            queue: .main
        ) { [weak self] notification in
            self?.handleAudioSessionInterruption(notification: notification)
        }
        notificationObservers.append(observer)
    }
    
    func handleAudioSessionInterruption(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else { return }
        if type == .began {
            print("Audio session interruption began")
            audioPlayer?.pause()
        } else if type == .ended {
            print("Audio session interruption ended")
            do {
                try AVAudioSession.sharedInstance().setActive(true)
                audioPlayer?.play()
            } catch {
                print("Failed to reactivate audio session after interruption: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Audio Player Setup
    private func setupAudioPlayerSecurely() {
        guard let soundURL = Bundle.main.url(forResource: "Mockingbird", withExtension: "mp3") else {
            print("Could not find Mockingbird.mp3 file")
            return
        }
        
        // Validate file exists and is readable
        guard FileManager.default.fileExists(atPath: soundURL.path),
              FileManager.default.isReadableFile(atPath: soundURL.path) else {
            print("Audio file is not accessible or readable")
            return
        }
        
        // Check file size to prevent loading extremely large files
        do {
            let fileAttributes = try FileManager.default.attributesOfItem(atPath: soundURL.path)
            if let fileSize = fileAttributes[FileAttributeKey.size] as? NSNumber {
                let fileSizeInMB = fileSize.doubleValue / (1024 * 1024)
                guard fileSizeInMB < 50 else { // Limit to 50MB
                    print("Audio file too large: \(fileSizeInMB)MB")
                    return
                }
            }
        } catch {
            print("Could not get file attributes: \(error.localizedDescription)")
            return
        }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
            audioPlayer?.numberOfLoops = -1 // Loop indefinitely
            audioPlayer?.volume = 1.0
            
            // Validate player was created successfully
            guard let player = audioPlayer else {
                print("Failed to create audio player")
                return
            }
            
            let prepareResult = player.prepareToPlay()
            if !prepareResult {
                print("Audio player failed to prepare")
                audioPlayer = nil
            }
            
        } catch {
            print("Failed to initialize audio player: \(error.localizedDescription)")
            audioPlayer = nil
        }
    }
    
    // MARK: - Audio Playback
    func playAlarmSound() {
        guard let player = audioPlayer else {
            print("Audio player not available")
            return
        }
        
        // Prevent multiple play attempts if already playing
        guard !player.isPlaying else {
            print("Alarm sound already playing")
            return
        }
        // Override silent mode and set system volume to lowest level
        do {
            let audioSession = AVAudioSession.sharedInstance()
            guard !audioSession.isOtherAudioPlaying else {
                print("Cannot play alarm - other audio is active")
                return
            }
            try audioSession.setCategory(.playback, mode: .default, options: [])
            try audioSession.setActive(true)
            setSystemVolumeDirectly(to: 0.1)
            player.volume = 1.0
            let playResult = player.play()
            if playResult {
                print("Alarm sound started - system volume set to 10%")
            } else {
                print("Failed to start audio playback")
            }
        } catch let error as NSError {
            print("Failed to override silent mode: \(error.localizedDescription)")
            if error.code == AVAudioSession.ErrorCode.cannotStartPlaying.rawValue {
                print("Cannot start playing - system restriction")
            }
            setSystemVolumeDirectly(to: 0.1)
            let playResult = player.play()
            if playResult {
                print("Fallback alarm sound started")
            }
        } catch {
            print("Unexpected audio playbook error: \(error.localizedDescription)")
        }
    }
    
    func stopAlarmSound() {
        audioPlayer?.stop()
        
        // Restore original audio session settings
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .default)
        } catch {
            print("Failed to restore audio session: \(error)")
        }
    }
    
    // MARK: - Volume Control
    private func setSystemVolumeDirectly(to volume: Float) {
        // Use compatibility layer for cross-version volume control
        VolumeControlCompat.setSystemVolume(volume)
    }
    
    func setSystemVolume(to volume: Float) {
        print("Setting system volume to: \(volume)")
        VolumeControlCompat.setSystemVolume(volume)
    }
    
    func setSystemVolumeSafely(_ volume: Float) {
        let safeVolume = min(max(volume, 0.0), 1.0)
        if let last = lastVolumeSet, abs(last - safeVolume) < 0.01 { return }
        setSystemVolumeDirectly(to: safeVolume)
        lastVolumeSet = safeVolume
    }
    
    // MARK: - Resource Management
    func preloadAudioResources() {
        // Preload audio in background to avoid UI blocking
        DispatchQueue.global(qos: .utility).async { [weak self] in
            self?.setupAudioPlayerSecurely()
        }
    }
    
    func cleanupAudioResources() {
        audioPlayer?.stop()
        audioPlayer?.prepareToPlay() // Reset to prepared state
        audioPlayer = nil // Explicit cleanup
        
        // Reset audio session
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            print("Failed to deactivate audio session: \(error.localizedDescription)")
        }
        
        // Remove observers
        for observer in notificationObservers {
            NotificationCenter.default.removeObserver(observer)
        }
        notificationObservers.removeAll()
    }
}
