//
//  DeckSelectionView.swift
//  IELTS flashcards
//
//  Created by Mario Moschetta on 18/10/25.
//

import SwiftUI

struct DeckSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: StudySessionViewModel
    @State private var selectedDeckIds: Set<String> = []
    @State private var availableDecks: [DeckInfo] = []
    @State private var isLoadingDecks = true
    
    @Environment(\.colorScheme) private var colorScheme
    
    init(viewModel: StudySessionViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if isLoadingDecks {
                    ProgressView("app.loading".localized)
                        .tint(AppColors.secondary(colorScheme))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            Text("deck.selection.subtitle".localized)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                                .padding(.top)
                            
                            ForEach(availableDecks) { deck in
                                DeckCard(
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
                        .padding(.bottom)
                    }
                }
            }
            .navigationTitle("deck.selection.title".localized)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.done".localized) {
                        applySelection()
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        selectedDeckIds = Set(availableDecks.map { $0.id })
                    } label: {
                        Text("deck.selection.all".localized)
                            .font(.subheadline)
                    }
                }
            }
            .task {
                await loadDecks()
            }
        }
    }
    
    private func loadDecks() async {
        await viewModel.loadIfNeeded()
        
        let cards = try? VocabularyRepository().loadAllCards()
        
        let decks = viewModel.availableDecks.map { deck in
            let cardCount = cards?.filter { $0.deckId == deck.id }.count ?? 0
            return DeckInfo(
                id: deck.id,
                name: deck.name,
                description: deck.description,
                cardCount: cardCount
            )
        }
        
        availableDecks = decks.sorted { lhs, rhs in
            if lhs.id == Flashcard.defaultDeckId {
                return true
            }
            if rhs.id == Flashcard.defaultDeckId {
                return false
            }
            return lhs.name.localizedCompare(rhs.name) == .orderedAscending
        }
        
        selectedDeckIds = viewModel.selectedDeckId.map { [$0] } ?? []
        isLoadingDecks = false
    }
    
    private func applySelection() {
        if selectedDeckIds.isEmpty {
            viewModel.setDeck(id: nil)
        } else if selectedDeckIds.count == 1 {
            viewModel.setDeck(id: selectedDeckIds.first)
        } else {
            viewModel.setDeck(id: nil)
        }
    }
}

struct DeckInfo: Identifiable {
    let id: String
    let name: String
    let description: String
    let cardCount: Int
}

private struct DeckCard: View {
    let deck: DeckInfo
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
                            .lineLimit(3)
                    }
                    
                    Label("deck.selection.cards".localized(with: deck.cardCount), systemImage: "rectangle.stack")
                        .font(.caption)
                        .foregroundStyle(AppColors.secondary(colorScheme))
                }
                
                Spacer()
                
                VStack(spacing: 8) {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.title2)
                        .foregroundStyle(isSelected ? AppColors.primary(colorScheme) : .secondary)
                    
                    Text(isSelected ? "deck.selection.deselect".localized : "deck.selection.select".localized)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
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


