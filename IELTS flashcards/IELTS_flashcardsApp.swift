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
            ContentView(viewModel: StudySessionViewModel())
                .accentColor(AppColors.secondary)
                .tint(AppColors.secondary)
                .task {
                    await NotificationManager.shared.ensureDailyReviewReminder()
                }
        }
    }
}
