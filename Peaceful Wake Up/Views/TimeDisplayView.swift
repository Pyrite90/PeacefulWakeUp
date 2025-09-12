//
//  TimeDisplayView.swift
//  Peaceful Wake Up
//
//  Created by Mike McDonald on 9/11/25.
//

import SwiftUI

struct TimeDisplayView: View {
    let currentTime: Date
    let alarmTime: Date?
    let isAlarmSet: Bool
    let timeUntilAlarm: String
    let onTapGesture: () -> Void
    
    var body: some View {
        VStack {
            // Current time display - centered vertically
            Text(currentTime, format: Date.FormatStyle()
                .hour(.twoDigits(amPM: .omitted))
                .minute(.twoDigits)
                .second(.twoDigits))
                .font(.system(size: 48, weight: .light, design: .rounded))
                .foregroundColor(.white.opacity(0.9))
                .onTapGesture {
                    onTapGesture()
                }
            
            // Active alarm time display right under current time
            if isAlarmSet, let alarmTime = alarmTime {
                Text("Alarm: \(alarmTime, format: Date.FormatStyle(date: .omitted, time: .shortened))")
                    .font(.title3)
                    .fontWeight(.light)
                    .foregroundColor(.white.opacity(0.7))
                    .padding(.top, 10)
                    .onTapGesture {
                        onTapGesture()
                    }
                
                // Time remaining until alarm
                Text(timeUntilAlarm)
                    .font(.title3)
                    .fontWeight(.light)
                    .foregroundColor(.white.opacity(0.6))
                    .padding(.top, 5)
                    .onTapGesture {
                        onTapGesture()
                    }
            }
        }
    }
}

#Preview {
    TimeDisplayView(
        currentTime: Date(),
        alarmTime: Date().addingTimeInterval(3600),
        isAlarmSet: true,
        timeUntilAlarm: "1 hour, 0 minutes",
        onTapGesture: {}
    )
    .background(.black)
}