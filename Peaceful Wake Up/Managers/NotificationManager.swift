//
//  NotificationManager.swift
//  Peaceful Wake Up
//
//  Created by Mike McDonald on 9/26/25.
//

import Foundation
import UIKit

// MARK: - Notification Management
class NotificationManager: ObservableObject, NotificationManaging {
    private var notificationObservers: [NSObjectProtocol] = []
    
    // MARK: - Notification Observer Management
    func setupNotificationObservers(
        onMemoryWarning: @escaping () -> Void,
        onAudioInterruption: @escaping (Notification) -> Void
    ) {
        // Clear any existing observers first
        removeNotificationObservers()
        
        let audioInterruptionObserver = NotificationCenter.default.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: AVAudioSession.sharedInstance(),
            queue: .main
        ) { notification in
            onAudioInterruption(notification)
        }
        
        let memoryWarningObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification,
            object: nil,
            queue: .main
        ) { _ in
            onMemoryWarning()
        }
        
        notificationObservers = [audioInterruptionObserver, memoryWarningObserver]
    }
    
    func removeNotificationObservers() {
        for observer in notificationObservers {
            NotificationCenter.default.removeObserver(observer)
        }
        notificationObservers.removeAll()
    }
    
    deinit {
        removeNotificationObservers()
    }
}
