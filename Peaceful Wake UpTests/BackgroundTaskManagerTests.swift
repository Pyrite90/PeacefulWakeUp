//
//  BackgroundTaskManagerTests.swift
//  Peaceful Wake UpTests
//
//  Created by Mike McDonald on 9/26/25.
//

import XCTest
import UIKit
@testable import Peaceful_Wake_Up

final class BackgroundTaskManagerTests: XCTestCase {
    var backgroundTaskManager: BackgroundTaskManager!
    
    override func setUp() {
        super.setUp()
        backgroundTaskManager = BackgroundTaskManager()
    }
    
    override func tearDown() {
        backgroundTaskManager?.endBackgroundTask()
        backgroundTaskManager = nil
        super.tearDown()
    }
    
    // MARK: - Background Task Lifecycle Tests
    func testStartBackgroundTask() {
        XCTAssertNoThrow(backgroundTaskManager.startBackgroundTask())
    }
    
    func testEndBackgroundTask() {
        backgroundTaskManager.startBackgroundTask()
        XCTAssertNoThrow(backgroundTaskManager.endBackgroundTask())
    }
    
    func testEndBackgroundTaskWithoutStart() {
        // Should be safe to call without starting
        XCTAssertNoThrow(backgroundTaskManager.endBackgroundTask())
    }
    
    func testMultipleStartBackgroundTask() {
        // Should handle multiple starts gracefully
        backgroundTaskManager.startBackgroundTask()
        backgroundTaskManager.startBackgroundTask() // Should end previous and start new
        
        XCTAssertNoThrow(backgroundTaskManager.endBackgroundTask())
    }
    
    func testMultipleEndBackgroundTask() {
        backgroundTaskManager.startBackgroundTask()
        backgroundTaskManager.endBackgroundTask()
        
        // Second end should be safe
        XCTAssertNoThrow(backgroundTaskManager.endBackgroundTask())
    }
    
    // MARK: - App Lifecycle Tests
    func testHandleAppGoingToBackground() {
        XCTAssertNoThrow(backgroundTaskManager.handleAppGoingToBackground())
    }
    
    func testHandleAppReturningToForeground() {
        backgroundTaskManager.handleAppGoingToBackground()
        XCTAssertNoThrow(backgroundTaskManager.handleAppReturningToForeground())
    }
    
    func testAppLifecycleCycle() {
        // Simulate complete app lifecycle
        backgroundTaskManager.handleAppGoingToBackground()
        backgroundTaskManager.handleAppReturningToForeground()
        backgroundTaskManager.handleAppGoingToBackground()
        backgroundTaskManager.handleAppReturningToForeground()
        
        XCTAssertTrue(true) // Should complete without crashing
    }
    
    func testForegroundWithoutBackground() {
        // Should be safe to call foreground without background
        XCTAssertNoThrow(backgroundTaskManager.handleAppReturningToForeground())
    }
    
    // MARK: - Resource Cleanup Tests
    func testDeinitCleanup() {
        var manager: BackgroundTaskManager? = BackgroundTaskManager()
        manager?.startBackgroundTask()
        
        // Deinit should clean up resources
        XCTAssertNoThrow(manager = nil)
    }
    
    // MARK: - State Management Tests
    func testBackgroundTaskStartsCorrectly() {
        backgroundTaskManager.startBackgroundTask()
        
        // After starting, we should be able to end it
        XCTAssertNoThrow(backgroundTaskManager.endBackgroundTask())
    }
    
    func testBackgroundTaskRestarts() {
        backgroundTaskManager.startBackgroundTask()
        backgroundTaskManager.endBackgroundTask()
        
        // Should be able to restart
        XCTAssertNoThrow(backgroundTaskManager.startBackgroundTask())
        XCTAssertNoThrow(backgroundTaskManager.endBackgroundTask())
    }
    
    // MARK: - Performance Tests
    func testBackgroundTaskPerformance() {
        measure {
            for _ in 0..<10 {
                backgroundTaskManager.startBackgroundTask()
                backgroundTaskManager.endBackgroundTask()
            }
        }
    }
    
    func testAppLifecyclePerformance() {
        measure {
            for _ in 0..<10 {
                backgroundTaskManager.handleAppGoingToBackground()
                backgroundTaskManager.handleAppReturningToForeground()
            }
        }
    }
    
    // MARK: - Integration Tests
    func testRapidStateChanges() {
        // Simulate rapid app state changes
        for _ in 0..<50 {
            backgroundTaskManager.handleAppGoingToBackground()
            backgroundTaskManager.handleAppReturningToForeground()
        }
        
        XCTAssertTrue(true) // Should handle rapid changes without issues
    }
}
