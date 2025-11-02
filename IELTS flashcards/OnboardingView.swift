//
//  OnboardingView.swift
//  IELTS flashcards
//
//  Created by Mario Moschetta on 18/10/25.
//

import SwiftUI

struct OnboardingView: View {
    @Binding var isCompleted: Bool
    @State private var currentPage = 0
    @State private var selectedDeckIds: Set<String> = []
    @State private var availableDecks: [OnboardingDeckInfo] = []
    @State private var isLoadingDecks = true
    
    @Environment(\.colorScheme) private var colorScheme
    
    private let totalPages = 5
    
    var body: some View {
        TabView(selection: $currentPage) {
            WelcomePageView()
                .tag(0)
            
            PhilosophyPage1View()
                .tag(1)
            
            PhilosophyPage2View()
                .tag(2)
            
            PhilosophyPage3View()
                .tag(3)
            
            TutorialPageView()
                .tag(4)
            
            DeckSelectionPageView(
                selectedDeckIds: $selectedDeckIds,
                availableDecks: availableDecks,
                isLoadingDecks: isLoadingDecks,
                onComplete: completeOnboarding
            )
            .tag(5)
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
        .indexViewStyle(.page(backgroundDisplayMode: .always))
        .onAppear {
            loadDecks()
        }
    }
    
    private func loadDecks() {
        Task {
            do {
                let cards = try VocabularyRepository().loadAllCards()
                let groupedDecks = Dictionary(grouping: cards, by: { $0.deckId })
                
                await MainActor.run {
                    availableDecks = groupedDecks.map { key, values in
                        let representative = values.first
                        return OnboardingDeckInfo(
                            id: key,
                            name: representative?.deckName ?? key.capitalized,
                            description: representative?.deckDescription ?? "",
                            cardCount: values.count
                        )
                    }
                    .sorted { lhs, rhs in
                        if lhs.id == Flashcard.defaultDeckId {
                            return true
                        }
                        if rhs.id == Flashcard.defaultDeckId {
                            return false
                        }
                        return lhs.name.localizedCompare(rhs.name) == .orderedAscending
                    }
                    isLoadingDecks = false
                }
            } catch {
                await MainActor.run {
                    isLoadingDecks = false
                }
            }
        }
    }
    
    private func completeOnboarding() {
        isCompleted = true
        OnboardingManager.shared.completeOnboarding(selectedDeckIds: Array(selectedDeckIds))
    }
}

struct OnboardingDeckInfo: Identifiable {
    let id: String
    let name: String
    let description: String
    let cardCount: Int
}

// MARK: - Welcome Page
private struct WelcomePageView: View {
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            VStack(spacing: 16) {
                Image(systemName: "book.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(AppColors.secondary(colorScheme))
                
                Text("app.name".localized)
                    .font(.largeTitle.weight(.bold))
                    .foregroundStyle(AppColors.secondary(colorScheme))
                
                Text("onboarding.welcome.subtitle".localized)
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
        }
        .padding()
    }
}

// MARK: - Philosophy Page 1
private struct PhilosophyPage1View: View {
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            VStack(spacing: 24) {
                Image(systemName: "timer")
                    .font(.system(size: 80))
                    .foregroundStyle(AppColors.primary(colorScheme))
                
                Text("onboarding.philosophy1.title".localized)
                    .font(.largeTitle.weight(.bold))
                    .foregroundStyle(AppColors.secondary(colorScheme))
                
                Text("onboarding.philosophy1.subtitle".localized)
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            Spacer()
        }
        .padding()
    }
}

// MARK: - Philosophy Page 2
private struct PhilosophyPage2View: View {
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            VStack(spacing: 24) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 80))
                    .foregroundStyle(AppColors.speaking(colorScheme))
                
                Text("onboarding.philosophy2.title".localized)
                    .font(.largeTitle.weight(.bold))
                    .foregroundStyle(AppColors.secondary(colorScheme))
                
                VStack(spacing: 12) {
                    Text("onboarding.philosophy2.subtitle".localized)
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(AppColors.primary(colorScheme))
                    
                    Text("onboarding.philosophy2.subtitle2".localized)
                        .font(.title3)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal)
            }
            
            Spacer()
        }
        .padding()
    }
}

// MARK: - Philosophy Page 3
private struct PhilosophyPage3View: View {
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            VStack(spacing: 24) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(AppColors.reading(colorScheme))
                
                Text("onboarding.philosophy3.title".localized)
                    .font(.largeTitle.weight(.bold))
                    .foregroundStyle(AppColors.secondary(colorScheme))
                
                VStack(spacing: 12) {
                    Text("onboarding.philosophy3.subtitle".localized)
                        .font(.title3)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Text("onboarding.philosophy3.subtitle2".localized)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal)
            }
            
            Spacer()
        }
        .padding()
    }
}

// MARK: - Tutorial Page
private struct TutorialPageView: View {
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            VStack(spacing: 24) {
                Image(systemName: "hand.draw.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(AppColors.listening(colorScheme))
                
                Text("onboarding.tutorial.title".localized)
                    .font(.largeTitle.weight(.bold))
                    .foregroundStyle(AppColors.secondary(colorScheme))
                
                VStack(spacing: 16) {
                    Text("onboarding.tutorial.subtitle".localized)
                        .font(.title3)
                        .foregroundStyle(.secondary)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("onboarding.tutorial.swipe".localized)
                            .font(.headline)
                            .foregroundStyle(AppColors.secondary(colorScheme))
                        
                        HStack(spacing: 16) {
                            VStack(spacing: 4) {
                                Image(systemName: "arrow.left")
                                    .foregroundStyle(AppColors.reviewAgain(colorScheme))
                                Text("onboarding.tutorial.swipe.left".localized)
                                    .font(.caption)
                            }
                            
                            VStack(spacing: 4) {
                                Image(systemName: "arrow.up")
                                    .foregroundStyle(AppColors.reviewGood(colorScheme))
                                Text("onboarding.tutorial.swipe.up".localized)
                                    .font(.caption)
                            }
                            
                            VStack(spacing: 4) {
                                Image(systemName: "arrow.right")
                                    .foregroundStyle(AppColors.reviewEasy(colorScheme))
                                Text("onboarding.tutorial.swipe.right".localized)
                                    .font(.caption)
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
            
            Spacer()
        }
        .padding()
    }
}

// MARK: - Deck Selection Page
private struct DeckSelectionPageView: View {
    @Binding var selectedDeckIds: Set<String>
    let availableDecks: [OnboardingDeckInfo]
    let isLoadingDecks: Bool
    let onComplete: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 12) {
                Text("onboarding.decks.title".localized)
                    .font(.largeTitle.weight(.bold))
                    .foregroundStyle(AppColors.secondary(colorScheme))
                
                Text("onboarding.decks.subtitle".localized)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 40)
            
            if isLoadingDecks {
                ProgressView()
                    .tint(AppColors.secondary(colorScheme))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(availableDecks) { deck in
                            DeckSelectionCard(
                                deck: deck,
                                isSelected: selectedDeckIds.contains(deck.id),
                                onToggle: {
                                    if selectedDeckIds.contains(deck.id) {
                                        selectedDeckIds.remove(deck.id)
                                    } else {
                                        selectedDeckIds.insert(deck.id)
                                    }
                                }
                            )
                        }
                    }
                    .padding(.horizontal)
                }
            }
            
            Button(action: {
                if selectedDeckIds.isEmpty {
                    selectedDeckIds = Set(availableDecks.map { $0.id })
                }
                onComplete()
            }) {
                Text("onboarding.decks.button".localized)
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            .buttonStyle(.borderedProminent)
            .tint(AppColors.secondary(colorScheme))
            .padding(.horizontal)
            .padding(.bottom, 20)
        }
    }
}

private struct DeckSelectionCard: View {
    let deck: OnboardingDeckInfo
    let isSelected: Bool
    let onToggle: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(deck.name)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    if !deck.description.isEmpty {
                        Text(deck.description)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                    
                    Text("deck.selection.cards".localized(with: deck.cardCount))
                        .font(.caption)
                        .foregroundStyle(AppColors.secondary(colorScheme))
                }
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(isSelected ? AppColors.primary(colorScheme) : .secondary)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(colorScheme == .dark ? Color(.systemGray6) : Color(.systemBackground))
                    .shadow(color: AppColors.secondary(colorScheme).opacity(0.1), radius: 8, x: 0, y: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? AppColors.primary(colorScheme) : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Onboarding Manager
final class OnboardingManager {
    static let shared = OnboardingManager()
    
    private let onboardingCompletedKey = "onboarding_completed"
    private let selectedDecksKey = "selected_decks"
    
    private init() {}
    
    func isOnboardingCompleted() -> Bool {
        UserDefaults.standard.bool(forKey: onboardingCompletedKey)
    }
    
    func completeOnboarding(selectedDeckIds: [String] = []) {
        UserDefaults.standard.set(true, forKey: onboardingCompletedKey)
        if !selectedDeckIds.isEmpty {
            UserDefaults.standard.set(selectedDeckIds, forKey: selectedDecksKey)
        }
    }
    
    func resetOnboarding() {
        UserDefaults.standard.removeObject(forKey: onboardingCompletedKey)
        UserDefaults.standard.removeObject(forKey: selectedDecksKey)
    }
    
    func getInitialSelectedDecks() -> [String]? {
        UserDefaults.standard.array(forKey: selectedDecksKey) as? [String]
    }
}

