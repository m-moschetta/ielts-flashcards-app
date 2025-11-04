//
//  ContentView.swift
//  IELTS flashcards
//
//  Created by Mario Moschetta on 18/10/25.
//

import SwiftUI
import Combine
import UIKit

// MARK: - Design System Colors (Pathway Aligned)
struct AppColors {
    static func primary(_ colorScheme: ColorScheme) -> Color {
        color(forLight: Color(red: 226/255, green: 52/255, blue: 52/255), dark: Color(red: 255/255, green: 112/255, blue: 112/255), colorScheme: colorScheme)
    }
    static func secondary(_ colorScheme: ColorScheme) -> Color {
        color(forLight: Color(red: 43/255, green: 43/255, blue: 108/255), dark: Color(red: 160/255, green: 170/255, blue: 255/255), colorScheme: colorScheme)
    }
    static func writing(_ colorScheme: ColorScheme) -> Color {
        color(forLight: Color(red: 148/255, green: 168/255, blue: 202/255), dark: Color(red: 90/255, green: 115/255, blue: 180/255), colorScheme: colorScheme)
    }
    static func speaking(_ colorScheme: ColorScheme) -> Color {
        color(forLight: Color(red: 155/255, green: 177/255, blue: 117/255), dark: Color(red: 135/255, green: 210/255, blue: 140/255), colorScheme: colorScheme)
    }
    static func listening(_ colorScheme: ColorScheme) -> Color {
        color(forLight: Color(red: 250/255, green: 206/255, blue: 132/255), dark: Color(red: 255/255, green: 222/255, blue: 140/255), colorScheme: colorScheme)
    }
    static func reading(_ colorScheme: ColorScheme) -> Color {
        color(forLight: Color(red: 173/255, green: 135/255, blue: 194/255), dark: Color(red: 195/255, green: 160/255, blue: 230/255), colorScheme: colorScheme)
    }
    static func ai(_ colorScheme: ColorScheme) -> Color {
        color(forLight: Color(red: 229/255, green: 187/255, blue: 0/255), dark: Color(red: 239/255, green: 210/255, blue: 50/255), colorScheme: colorScheme)
    }
    
    // Semantic colors for review actions
    static func reviewAgain(_ colorScheme: ColorScheme) -> Color {
        color(forLight: Color(red: 251/255, green: 0/255, blue: 0/255), dark: Color(red: 255/255, green: 80/255, blue: 80/255), colorScheme: colorScheme)
    }
    static func reviewGood(_ colorScheme: ColorScheme) -> Color {
        reading(colorScheme) // Reading purple for "Good"
    }
    static func reviewEasy(_ colorScheme: ColorScheme) -> Color {
        speaking(colorScheme) // Speaking green for "Easy"
    }

    private static func color(forLight: Color, dark: Color, colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? dark : forLight
    }
}

struct ContentView: View {
    @StateObject private var viewModel: StudySessionViewModel
    @Environment(\.colorScheme) private var colorScheme

    @MainActor
    init(viewModel: StudySessionViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            content
                .padding()
                .navigationTitle("app.name".localized)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        VStack(spacing: 0) {
                            Text("app.name".localized)
                                .font(.headline.weight(.semibold))
                                .foregroundStyle(AppColors.secondary(colorScheme))
                        }
                    }
                    ToolbarItem(placement: .primaryAction) {
                        optionsMenu
                            .foregroundStyle(AppColors.secondary(colorScheme))
                    }
                }
                .toolbar {
                    ToolbarItem(placement: .keyboard) {
                        keyboardToolbar
                    }
                }
                .task {
                    await viewModel.loadIfNeeded()
                }
        }
    }

    @ViewBuilder
    private var content: some View {
        VStack(spacing: 24) {
            switch viewModel.state {
            case .loading:
                ProgressView("app.loading".localized)
                    .progressViewStyle(.circular)
                    .tint(AppColors.secondary(colorScheme))
            case let .failed(message):
                errorView(message: message)
            case let .ready(card):
                studyView(card: card)
            case .completed:
                completedView
            }
        }
    }

    @State private var showDeckSelection = false
    
    @ViewBuilder
    private var keyboardToolbar: some View {
        if !viewModel.showBack && !viewModel.userTranslation.isEmpty && !viewModel.isAnswerChecked {
            HStack {
                Spacer()
                Button("card.translation.check".localized) {
                    withAnimation(.easeInOut) {
                        viewModel.checkAnswer()
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(AppColors.reading(colorScheme))
            }
        } else {
            HStack {
                Spacer()
            }
        }
    }
    
    private var optionsMenu: some View {
        Menu {
            Section("menu.deck".localized) {
                Button {
                    withAnimation {
                        viewModel.setDeck(id: nil)
                    }
                } label: {
                    HStack(spacing: 8) {
                        Text(StudySessionViewModel.allDecksLabel)
                        if viewModel.selectedDeckId == nil {
                            Image(systemName: "checkmark")
                                .foregroundStyle(AppColors.primary(colorScheme))
                        }
                    }
                }

                ForEach(viewModel.availableDecks) { deck in
                    Button {
                        withAnimation {
                            viewModel.setDeck(id: deck.id)
                        }
                    } label: {
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 8) {
                                Text(deck.name)
                                if viewModel.selectedDeckId == deck.id {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(AppColors.primary(colorScheme))
                                }
                            }
                            if !deck.description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                Text(deck.description)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                
                Divider()
                
                Button {
                    showDeckSelection = true
                } label: {
                    Label("menu.select.decks".localized, systemImage: "square.grid.2x2")
                }
            }

            Divider()

            Section("menu.level".localized) {
                ForEach(Array(viewModel.availableLevels.enumerated()), id: \.offset) { _, level in
                    Button {
                        withAnimation {
                            viewModel.setLevel(level)
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Text(level)
                            if viewModel.selectedLevel == level {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(AppColors.primary(colorScheme))
                            }
                        }
                    }
                }
            }

            Divider()

            Button(role: .destructive) {
                withAnimation {
                    viewModel.resetProgress()
                }
            } label: {
                Label("menu.reset.progress".localized, systemImage: "arrow.counterclockwise")
            }
        } label: {
            Image(systemName: "line.3.horizontal.decrease.circle")
                .foregroundStyle(AppColors.secondary(colorScheme))
        }
        .sheet(isPresented: $showDeckSelection) {
            DeckSelectionView(viewModel: viewModel)
        }
    }

    @ViewBuilder
    private func errorView(message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.title)
                .foregroundStyle(AppColors.primary(colorScheme))
            
            Text("app.error.title".localized)
                .font(.title3.weight(.semibold))
                .foregroundStyle(AppColors.secondary(colorScheme))
            
            Text(message)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .font(.caption)
            
            Button("app.error.retry".localized) {
                Task { await viewModel.load() }
            }
            .buttonStyle(.borderedProminent)
            .tint(AppColors.secondary(colorScheme))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }

    @ViewBuilder
    private func studyView(card: Flashcard) -> some View {
        GeometryReader { proxy in
            let cardHeight = max(proxy.size.height * 0.6, 360)

            VStack(spacing: 20) {
                StudyHeaderView(
                    currentPosition: viewModel.currentPosition,
                    totalCount: viewModel.totalCount,
                    dueCount: viewModel.dueCount,
                    deckName: viewModel.selectedDeckTitle,
                    levelName: viewModel.selectedLevelTitle
                )

                SwipeableFlashcardView(
                    card: card,
                    showBack: viewModel.showBack,
                    userTranslation: viewModel.userTranslation,
                    isAnswerChecked: viewModel.isAnswerChecked,
                    onTranslationChanged: { newTranslation in
                        viewModel.userTranslation = newTranslation
                    },
                    onToggle: {
                        Haptics.selection()
                        withAnimation(.easeInOut) {
                            viewModel.toggleCard()
                        }
                    },
                    onCheckAnswer: {
                        withAnimation(.easeInOut) {
                            viewModel.checkAnswer()
                        }
                    },
                    onSwipe: { outcome in
                        withAnimation(.easeIn) {
                            viewModel.review(outcome)
                        }
                    }
                )
                .frame(height: cardHeight)

                if viewModel.showBack && !viewModel.isAnswerChecked {
                    Text("study.swipe.hint".localized)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                } else if !viewModel.showBack {
                    Text("card.translation.input".localized)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                }

                Spacer(minLength: 12)

                StudyActionsView(
                    canReview: viewModel.canReviewCurrentCard,
                    onAgain: { viewModel.review(.again) },
                    onGood: { viewModel.review(.good) },
                    onEasy: { viewModel.review(.easy) }
                )

                StudyProgressSummaryView(
                    studiedCount: max(viewModel.totalCount - viewModel.dueCount, 0),
                    totalCount: viewModel.totalCount
                )
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
    }

    private var completedView: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(AppColors.speaking(colorScheme))
            
            Text("app.completed.title".localized)
                .font(.title3.weight(.semibold))
                .foregroundStyle(AppColors.secondary(colorScheme))
            
            Text("app.completed.subtitle".localized)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .font(.caption)
            
            Button(role: .destructive) {
                withAnimation {
                    viewModel.resetProgress()
                }
            } label: {
                Label("app.completed.reset".localized, systemImage: "arrow.counterclockwise")
            }
            .buttonStyle(.bordered)
            .foregroundStyle(AppColors.primary(colorScheme))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }
}

private struct SwipeableFlashcardView: View {
    let card: Flashcard
    let showBack: Bool
    let userTranslation: String
    let isAnswerChecked: Bool
    let onTranslationChanged: (String) -> Void
    let onToggle: () -> Void
    let onCheckAnswer: () -> Void
    let onSwipe: (ReviewOutcome) -> Void

    @State private var translation: CGSize = .zero
    @State private var isDragging = false
    @State private var isAnimatingOut = false
    @Environment(\.colorScheme) var colorScheme

    private let horizontalThreshold: CGFloat = 100
    private let verticalThreshold: CGFloat = 100

    var body: some View {
        FlashcardStudyCard(
            card: card,
            showBack: showBack,
            userTranslation: userTranslation,
            isAnswerChecked: isAnswerChecked,
            onTranslationChanged: onTranslationChanged,
            onCheckAnswer: onCheckAnswer
        )
            .contentShape(Rectangle())
            .offset(translation)
            .rotationEffect(.degrees(Double(translation.width / 15)))
            .scaleEffect(isDragging ? 0.98 : 1.0)
            .overlay(alignment: .topLeading) {
                if showBack && isAnswerChecked && translation.width < -60 {
                    SwipeBadge(text: "study.again".localized, color: AppColors.reviewAgain(colorScheme))
                        .padding(16)
                }
            }
            .overlay(alignment: .topTrailing) {
                if showBack && isAnswerChecked && translation.width > 60 {
                    SwipeBadge(text: "study.easy".localized, color: AppColors.reviewEasy(colorScheme))
                        .padding(16)
                }
            }
            .overlay(alignment: .top) {
                if showBack && isAnswerChecked && translation.height < -60 {
                    SwipeBadge(text: "study.good".localized, color: AppColors.reviewGood(colorScheme))
                        .padding(.top, 28)
                }
            }
            .gesture(dragGesture)
            .onTapGesture {
                if isAnswerChecked {
                    onToggle()
                }
            }
    }

    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                guard showBack && isAnswerChecked, !isAnimatingOut else { return }
                translation = value.translation
                isDragging = true
            }
            .onEnded { value in
                isDragging = false
                guard showBack && isAnswerChecked, !isAnimatingOut else {
                    resetPosition()
                    return
                }

                if let outcome = resolveOutcome(for: value.translation) {
                    animateOut(for: outcome)
                } else {
                    resetPosition()
                }
            }
    }

    private func resolveOutcome(for translation: CGSize) -> ReviewOutcome? {
        if translation.width <= -horizontalThreshold {
            return .again
        }
        if translation.width >= horizontalThreshold {
            return .easy
        }
        if translation.height <= -verticalThreshold {
            return .good
        }
        return nil
    }

    private func animateOut(for outcome: ReviewOutcome) {
        isAnimatingOut = true
        let finalOffset = targetOffset(for: outcome)

        Haptics.outcome(outcome)

        withAnimation(.easeIn(duration: 0.2)) {
            translation = finalOffset
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
            onSwipe(outcome)
            translation = .zero
            isAnimatingOut = false
        }
    }

    private func resetPosition() {
        withAnimation(.interactiveSpring(response: 0.4, dampingFraction: 0.75)) {
            translation = .zero
        }
    }

    private func targetOffset(for outcome: ReviewOutcome) -> CGSize {
        switch outcome {
        case .again:
            return CGSize(width: -800, height: 0)
        case .good:
            return CGSize(width: 0, height: -800)
        case .easy:
            return CGSize(width: 800, height: 0)
        }
    }
}

private struct SwipeBadge: View {
    let text: String
    let color: Color
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        Text(text.uppercased())
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(color.opacity(0.9))
            .foregroundStyle(.white)
            .clipShape(Capsule())
    }
}

private enum Haptics {
    static func selection() {
        UISelectionFeedbackGenerator().selectionChanged()
    }

    static func outcome(_ outcome: ReviewOutcome) {
        let style: UIImpactFeedbackGenerator.FeedbackStyle
        switch outcome {
        case .again:
            style = .heavy
        case .good:
            style = .medium
        case .easy:
            style = .light
        }
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }
}

@MainActor
final class StudySessionViewModel: ObservableObject {
    enum ViewState {
        case loading
        case failed(String)
        case ready(Flashcard)
        case completed
    }
    static let allLevelsLabel = "menu.all.levels".localized
    static let allDecksLabel = "menu.all.decks".localized

    struct DeckFilter: Identifiable, Equatable {
        let id: String
        let name: String
        let description: String
    }

    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var availableDecks: [DeckFilter] = []
    @Published private(set) var selectedDeckId: String?
    @Published private(set) var availableLevels: [String] = []
    @Published private(set) var selectedLevel: String
    @Published private(set) var orderedCards: [Flashcard] = []
    @Published private(set) var currentCard: Flashcard?
    @Published var showBack = false
    @Published var userTranslation: String = ""
    @Published var isAnswerChecked: Bool = false

    private let loadCards: () throws -> [Flashcard]
    private let progressStore: FlashcardProgressStore
    private let scheduler: SpacedRepetitionScheduler
    private(set) var allCards: [Flashcard] = []
    private var progressById: [String: FlashcardProgress] = [:]
    private(set) var hasLoaded = false

    var state: ViewState {
        if isLoading {
            return .loading
        }
        if let errorMessage {
            return .failed(errorMessage)
        }
        if !hasLoaded {
            return .loading
        }
        if let currentCard {
            return .ready(currentCard)
        }
        return .completed
    }

    init(
        loadCards: @escaping () throws -> [Flashcard] = { try VocabularyRepository().loadAllCards() },
        progressStore: FlashcardProgressStore = FlashcardProgressStore(),
        scheduler: SpacedRepetitionScheduler = SpacedRepetitionScheduler(),
        initialCards: [Flashcard]? = nil,
        initialProgress: [String: FlashcardProgress]? = nil,
        selectedLevel: String = StudySessionViewModel.allLevelsLabel
    ) {
        self.loadCards = loadCards
        self.progressStore = progressStore
        self.scheduler = scheduler
        self.selectedLevel = selectedLevel

        if let initialCards {
            let progress = initialProgress ?? [:]
            configure(with: initialCards, initialProgress: progress)
            hasLoaded = true
        }
    }

    func load() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil

        do {
            let cards = try loadCards()
            let storedProgress = progressStore.allProgress()
            configure(with: cards, initialProgress: storedProgress)
            hasLoaded = true
        } catch {
            errorMessage = "app.error.title".localized + ": \(error.localizedDescription)"
        }

        isLoading = false
    }

    func loadIfNeeded() async {
        guard !hasLoaded else { return }
        await load()
    }

    func setLevel(_ level: String) {
        guard level != selectedLevel else { return }
        selectedLevel = level
        refreshQueue()
    }

    func setDeck(id: String?) {
        guard selectedDeckId != id else { return }
        selectedDeckId = id
        refreshQueue()
    }

    func toggleCard() {
        guard currentCard != nil else { return }
        if !showBack {
            showBack = true
        }
    }
    
    func checkAnswer() {
        guard let card = currentCard else { return }
        isAnswerChecked = true
        showBack = true
    }

    func review(_ outcome: ReviewOutcome) {
        guard let card = currentCard else { return }
        let now = Date()
        let currentProgress = progressById[card.id] ?? FlashcardProgress.new(now: now)
        let updated = scheduler.reviewed(card, current: currentProgress, outcome: outcome, now: now)

        progressById[card.id] = updated
        progressStore.setProgress(updated, for: card)

        showBack = false
        userTranslation = ""
        isAnswerChecked = false
        refreshQueue(now: now)
    }

    func resetProgress() {
        progressStore.reset()
        progressById.removeAll()
        showBack = false
        userTranslation = ""
        isAnswerChecked = false
        refreshQueue()
    }

    var canReviewCurrentCard: Bool {
        currentCard != nil && showBack && isAnswerChecked
    }

    var totalCount: Int {
        orderedCards.count
    }

    var dueCount: Int {
        let now = Date()
        return orderedCards.reduce(into: 0) { partialResult, card in
            let dueDate = progressById[card.id]?.dueDate ?? .distantPast
            if dueDate <= now {
                partialResult += 1
            }
        }
    }

    var currentPosition: Int {
        guard let currentCard, let index = orderedCards.firstIndex(of: currentCard) else {
            return 0
        }
        return index + 1
    }

    var selectedLevelTitle: String {
        selectedLevel
    }

    var selectedDeckTitle: String {
        guard let deckId = selectedDeckId,
              let deck = availableDecks.first(where: { $0.id == deckId }) else {
            return Self.allDecksLabel
        }
        return deck.name
    }

    private func configure(with cards: [Flashcard], initialProgress: [String: FlashcardProgress]) {
        allCards = cards

        let groupedDecks = Dictionary(grouping: cards, by: { $0.deckId })
        availableDecks = groupedDecks.map { key, values in
            let representative = values.first
            return DeckFilter(
                id: key,
                name: representative?.deckName ?? key.capitalized,
                description: representative?.deckDescription ?? ""
            )
        }
        .sorted(by: deckSortComparator)

        if let selectedDeckId,
           !availableDecks.contains(where: { $0.id == selectedDeckId }) {
            self.selectedDeckId = nil
        }

        let knownIds = Set(cards.map(\.id))
        progressById = initialProgress.reduce(into: [:]) { partialResult, element in
            if knownIds.contains(element.key) {
                partialResult[element.key] = element.value
            }
        }

        for card in cards {
            guard progressById[card.id] == nil else { continue }
            if let legacy = initialProgress[card.legacyIdentifier] {
                progressById[card.id] = legacy
            }
        }

        refreshQueue()
    }

    private func updateAvailableLevels(using cards: [Flashcard]) {
        let normalizedLevels = Set(cards.map { $0.normalizedLevel })
        availableLevels = [Self.allLevelsLabel] + normalizedLevels.sorted { $0.localizedCompare($1) == .orderedAscending }

        if !availableLevels.contains(selectedLevel) {
            selectedLevel = Self.allLevelsLabel
        }
    }

    private func deckPriority(for deckId: String) -> Int {
        switch deckId {
        case Flashcard.defaultDeckId:
            return 0
        default:
            return 1
        }
    }

    private func deckSortComparator(lhs: DeckFilter, rhs: DeckFilter) -> Bool {
        let leftPriority = deckPriority(for: lhs.id)
        let rightPriority = deckPriority(for: rhs.id)
        if leftPriority != rightPriority {
            return leftPriority < rightPriority
        }
        return lhs.name.localizedCompare(rhs.name) == .orderedAscending
    }

    private func refreshQueue(now: Date = Date()) {
        guard !allCards.isEmpty else {
            orderedCards = []
            currentCard = nil
            return
        }

        let deckFilteredCards: [Flashcard]
        if let selectedDeckId {
            deckFilteredCards = allCards.filter { $0.deckId == selectedDeckId }
        } else {
            deckFilteredCards = allCards
        }

        updateAvailableLevels(using: deckFilteredCards)

        let filteredCards: [Flashcard]
        if selectedLevel == Self.allLevelsLabel {
            filteredCards = deckFilteredCards
        } else {
            filteredCards = deckFilteredCards.filter { $0.normalizedLevel.caseInsensitiveCompare(selectedLevel) == .orderedSame }
        }

        orderedCards = scheduler.reorder(cards: filteredCards, with: progressById)

        let dueCards = orderedCards.filter { card in
            let dueDate = progressById[card.id]?.dueDate ?? .distantPast
            return dueDate <= now
        }

        currentCard = dueCards.first ?? orderedCards.first
        
        if currentCard != nil {
            userTranslation = ""
            isAnswerChecked = false
            showBack = false
        }
    }
}

private struct StudyHeaderView: View {
    let currentPosition: Int
    let totalCount: Int
    let dueCount: Int
    let deckName: String
    let levelName: String
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(spacing: 10) {
            HStack(alignment: .center) {
                Text(deckName)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(AppColors.secondary(colorScheme))
                    .lineLimit(1)
                Spacer()
                if totalCount > 0 {
                    Text("study.card.of".localized(with: currentPosition, totalCount))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            HStack(spacing: 12) {
                Text(levelName)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .background(AppColors.secondary(colorScheme))
                    .clipShape(Capsule())

                Spacer()

                Label("study.due.count".localized(with: dueCount), systemImage: "clock.arrow.circlepath")
                    .font(.caption)
                    .foregroundStyle(AppColors.primary(colorScheme).opacity(0.85))
                    .fontWeight(.medium)
            }
        }
    }
}

private struct FlashcardStudyCard: View {
    let card: Flashcard
    let showBack: Bool
    let userTranslation: String
    let isAnswerChecked: Bool
    let onTranslationChanged: (String) -> Void
    let onCheckAnswer: () -> Void
    @Environment(\.colorScheme) var colorScheme
    @FocusState private var isTextFieldFocused: Bool

    private var isCorrect: Bool {
        guard isAnswerChecked else { return false }
        let normalizedUserInput = userTranslation.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let normalizedCorrect = card.translation.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return normalizedUserInput == normalizedCorrect || 
               normalizedUserInput.contains(normalizedCorrect) || 
               normalizedCorrect.contains(normalizedUserInput)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(card.word.capitalized)
                .font(.largeTitle.weight(.bold))
                .foregroundStyle(AppColors.secondary(colorScheme))

            Divider()

            if !showBack {
                // Mostra campo di input per la traduzione
                VStack(alignment: .leading, spacing: 8) {
                    Text("card.translation.input".localized)
                        .font(.headline)
                        .foregroundStyle(AppColors.primary(colorScheme))
                    
                    HStack(spacing: 8) {
                        TextField("card.translation.input".localized, text: Binding(
                            get: { userTranslation },
                            set: { onTranslationChanged($0) }
                        ), axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .font(.title3)
                        .focused($isTextFieldFocused)
                        .lineLimit(2...4)
                        .disabled(isAnswerChecked)
                        .onSubmit {
                            if !userTranslation.isEmpty {
                                isTextFieldFocused = false
                                onCheckAnswer()
                            } else {
                                isTextFieldFocused = false
                            }
                        }
                        
                        if !userTranslation.isEmpty && !isAnswerChecked {
                            Button {
                                isTextFieldFocused = false
                                onCheckAnswer()
                            } label: {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.title2)
                                    .foregroundStyle(AppColors.reading(colorScheme))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            } else if isAnswerChecked {
                // Mostra feedback dopo la verifica
                VStack(alignment: .leading, spacing: 12) {
                    if isCorrect {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(AppColors.speaking(colorScheme))
                            Text("card.translation.correct".localized)
                                .foregroundStyle(AppColors.speaking(colorScheme))
                                .fontWeight(.semibold)
                        }
                    } else {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(AppColors.reviewAgain(colorScheme))
                                Text("card.translation.incorrect".localized)
                                    .foregroundStyle(AppColors.reviewAgain(colorScheme))
                                    .fontWeight(.semibold)
                            }
                            Text(card.translation)
                                .font(.title3)
                                .foregroundStyle(AppColors.primary(colorScheme))
                                .padding(.leading, 24)
                        }
                    }
                    
                    Divider()
                        .padding(.vertical, 4)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("card.definition".localized)
                                .font(.headline)
                                .foregroundStyle(AppColors.reading(colorScheme))
                            Text(card.definition)
                                .foregroundStyle(.primary)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("card.example".localized)
                                .font(.headline)
                                .foregroundStyle(AppColors.reading(colorScheme))
                            Text("\u{201C}\(card.example)\u{201D}")
                                .italic()
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                Text("card.tap.hint".localized)
                    .foregroundStyle(.secondary)
                    .italic()
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .frame(minHeight: 260)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(
                    colorScheme == .dark
                    ? LinearGradient(
                        gradient: Gradient(colors: [Color(.systemGray6), Color(.systemGray4)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                      )
                    : LinearGradient(
                        gradient: Gradient(colors: [
                            Color.white,
                            Color(red: 248/255, green: 248/255, blue: 255/255)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                      )
                )
                .shadow(color: AppColors.secondary(colorScheme).opacity(0.1), radius: 12, x: 0, y: 6)
        )
    }
}

private struct StudyActionsView: View {
    let canReview: Bool
    let onAgain: () -> Void
    let onGood: () -> Void
    let onEasy: () -> Void
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        HStack(spacing: 12) {
            StudyActionButton(
                title: "study.again".localized,
                subtitle: "study.again.time".localized,
                systemImage: "arrow.uturn.backward",
                tint: AppColors.reviewAgain(colorScheme),
                action: onAgain
            )

            StudyActionButton(
                title: "study.good".localized,
                subtitle: "study.good.time".localized,
                systemImage: "checkmark.circle",
                tint: AppColors.reviewGood(colorScheme),
                action: onGood
            )

            StudyActionButton(
                title: "study.easy".localized,
                subtitle: "study.easy.time".localized,
                systemImage: "sun.max",
                tint: AppColors.reviewEasy(colorScheme),
                action: onEasy
            )
        }
        .disabled(!canReview)
        .opacity(canReview ? 1 : 0.5)
    }
}

private struct StudyActionButton: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let tint: Color
    let action: () -> Void
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: systemImage)
                    .font(.title2)
                Text(title)
                    .font(.headline)
                Text(subtitle)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
        }
        .buttonStyle(.borderedProminent)
        .tint(tint)
    }
}

private struct StudyProgressSummaryView: View {
    let studiedCount: Int
    let totalCount: Int
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ProgressView(
                value: Double(studiedCount),
                total: Double(max(totalCount, 1))
            )
            .tint(AppColors.secondary(colorScheme))

            Text("study.progress".localized(with: studiedCount, totalCount))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 4)
    }
}

#Preview {
    let sampleCards = [
        Flashcard(
            word: "Analyze",
            level: "Base",
            definition: "To examine something in detail for explanation and interpretation.",
            example: "Students must analyze data before writing conclusions.",
            translation: "Analizzare"
        ),
        Flashcard(
            word: "Approach",
            level: "Base",
            definition: "A method or way of doing something.",
            example: "Her approach to the topic was innovative.",
            translation: "Approccio"
        )
    ]

    let sampleProgress: [String: FlashcardProgress] = [
        sampleCards[0].id: FlashcardProgress(
            easeFactor: 2.5,
            interval: 60 * 60 * 24,
            dueDate: Date().addingTimeInterval(-3600),
            repetitions: 2,
            lastReview: Date().addingTimeInterval(-3600)
        )
    ]

    return ContentView(
        viewModel: StudySessionViewModel(
            loadCards: { sampleCards },
            progressStore: FlashcardProgressStore(defaults: UserDefaults(suiteName: "preview") ?? .standard),
            scheduler: SpacedRepetitionScheduler(),
            initialCards: sampleCards,
            initialProgress: sampleProgress
        )
    )
}

