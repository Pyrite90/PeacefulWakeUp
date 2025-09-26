//
//  BackgroundTaskManager.swift
//  Peaceful Wake Up
//
//  Created by Mike McDonald on 9/26/25.
//

import UIKit
import Foundation

// MARK: - Background Task Management
class BackgroundTaskManager: ObservableObject, BackgroundTaskManaging {
    private var backgroundTaskID: UIBackgroundTaskIdentifier = .invalid
    
    // MARK: - Background Task Management
    func handleAppGoingToBackground() {
        startBackgroundTask()
    }
    
    func handleAppReturningToForeground() {
        endBackgroundTask()
    }
    
    func startBackgroundTask() {
        endBackgroundTask() // End any existing background task
        
        backgroundTaskID = UIApplication.shared.beginBackgroundTask(withName: "AlarmTimer") {
            self.endBackgroundTask()
        }
    }
    
    func endBackgroundTask() {
        if backgroundTaskID != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTaskID)
            backgroundTaskID = .invalid
        }
    }
    
    deinit {
        endBackgroundTask()
    }
}
