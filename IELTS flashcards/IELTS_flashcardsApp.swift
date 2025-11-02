//
//  IELTS_flashcardsApp.swift
//  IELTS flashcards
//
//  Created by Mario Moschetta on 18/10/25.
//

import SwiftUI

@main
struct IELTS_flashcardsApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
                .task {
                    await NotificationManager.shared.ensureDailyReviewReminder()
                }
        }
    }
}

private struct RootView: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var isOnboardingCompleted = OnboardingManager.shared.isOnboardingCompleted()

    var body: some View {
        Group {
            if isOnboardingCompleted {
                ContentView(viewModel: StudySessionViewModel())
                    .accentColor(AppColors.secondary(colorScheme))
                    .tint(AppColors.secondary(colorScheme))
            } else {
                OnboardingView(isCompleted: $isOnboardingCompleted)
                    .accentColor(AppColors.secondary(colorScheme))
                    .tint(AppColors.secondary(colorScheme))
            }
        }
    }
}
