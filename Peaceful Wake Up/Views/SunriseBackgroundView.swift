//
//  SunriseBackgroundView.swift
//  Peaceful Wake Up
//
//  Created by Mike McDonald on 9/11/25.
//

import SwiftUI

struct SunriseBackgroundView: View {
    var body: some View {
        LinearGradient(
            colors: [
                Color(red: 1.0, green: 0.4, blue: 0.0),      // Deep orange
                Color(red: 1.0, green: 0.6, blue: 0.2),      // Orange
                Color(red: 1.0, green: 0.8, blue: 0.4),      // Light orange
                Color(red: 1.0, green: 0.95, blue: 0.7)      // Pale yellow
            ],
            startPoint: .bottom,
            endPoint: .top
        )
        .ignoresSafeArea(.all)
    }
}

#Preview {
    SunriseBackgroundView()
}