//
//  AlarmControlsView.swift
//  Peaceful Wake Up
//
//  Created by Mike McDonald on 9/11/25.
//

import SwiftUI

struct AlarmControlsView: View {
    let isAlarmSet: Bool
    let showingAlarmSetter: Bool
    let buttonText: String
    let buttonColor: Color
    let onAlarmButton: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        // Only show controls when NOT showing the alarm setter
        // The AlarmSetterView has its own Confirm button
        if !showingAlarmSetter {
            if isAlarmSet {
                // Cancel Alarm slider
                VStack {
                    Text("Slide to Cancel Alarm")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                        .padding(.bottom, 5)
                    
                    SliderToCancelView(onCancel: onCancel)
                }
                .padding(.horizontal)
            } else {
                // Regular alarm button (Set Alarm)
                Button(action: onAlarmButton) {
                    Text(buttonText)
                        .font(.title2)
                        .fontWeight(.light)
                        .foregroundColor(.white.opacity(0.9))
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(buttonColor)
                        .cornerRadius(10)
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, UIScreen.main.bounds.width * 0.1) // Creates 80% width
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        AlarmControlsView(
            isAlarmSet: false,
            showingAlarmSetter: false,
            buttonText: "Set Alarm",
            buttonColor: .blue,
            onAlarmButton: {},
            onCancel: {}
        )
        
        AlarmControlsView(
            isAlarmSet: true,
            showingAlarmSetter: false,
            buttonText: "",
            buttonColor: .clear,
            onAlarmButton: {},
            onCancel: {}
        )
    }
    .padding()
    .background(.black)
}
