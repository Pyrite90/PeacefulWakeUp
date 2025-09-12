//
//  AlarmSetterView.swift
//  Peaceful Wake Up
//
//  Created by Mike McDonald on 9/11/25.
//

import SwiftUI

struct AlarmSetterView: View {
    @Binding var alarmTime: Date
    @Binding var isSilentAlarm: Bool
    @Binding var showingAlarmSetter: Bool
    let onConfirm: () -> Void
    
    var body: some View {
        VStack(alignment: .center, spacing: 12) {
            Text("Set Alarm Time")
                .font(.headline)
                .fontWeight(.medium)
                .foregroundColor(.white.opacity(0.9))
            
            DatePicker("", selection: $alarmTime, displayedComponents: .hourAndMinute)
                .datePickerStyle(.wheel)
            
            // Silent alarm checkbox
            HStack {
                Button(action: {
                    isSilentAlarm.toggle()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: isSilentAlarm ? "checkmark.square" : "square")
                            .foregroundColor(.white.opacity(0.8))
                            .font(.title3)
                        Text("Silent alarm (no sound)")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                Spacer()
            }
            .padding(.leading, 4)
            
            // Confirm button
            Button(action: onConfirm) {
                Text("Confirm Alarm")
                    .font(.title2)
                    .fontWeight(.light)
                    .foregroundColor(.white.opacity(0.9))
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(red: 1.0, green: 0.6, blue: 0.2).opacity(0.8))
                    .cornerRadius(10)
            }
        }
        .padding()
        .background(.white.opacity(0.1))
        .cornerRadius(15)
        .padding(.horizontal)
        .transition(.scale.combined(with: .opacity))
    }
}

#Preview {
    AlarmSetterView(
        alarmTime: .constant(Date()),
        isSilentAlarm: .constant(false),
        showingAlarmSetter: .constant(true),
        onConfirm: {}
    )
    .background(.black)
}