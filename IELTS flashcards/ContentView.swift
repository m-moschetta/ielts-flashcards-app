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
    static let primary = Color(red: 226/255, green: 52/255, blue: 52/255) // #e23434 - Red
    static let secondary = Color(red: 43/255, green: 43/255, blue: 108/255) // #2b2b6c - Dark Blue
    static let writing = Color(red: 148/255, green: 168/255, blue: 202/255) // #94a8ca - Light Blue
    static let speaking = Color(red: 155/255, green: 177/255, blue: 117/255) // #9bb175 - Green
    static let listening = Color(red: 250/255, green: 206/255, blue: 132/255) // #face84 - Yellow
    static let reading = Color(red: 173/255, green: 135/255, blue: 194/255) // #ad87c2 - Purple
    static let ai = Color(red: 229/255, green: 187/255, blue: 0/255) // #e5bb00 - Gold
    
    // Semantic colors for review actions
    static let reviewAgain = Color(red: 251/255, green: 0/255, blue: 0/255) // Red for "Again"
    static let reviewGood = reading // Reading purple for "Good"
    static let reviewEasy = speaking // Speaking green for "Easy"
}

struct ContentView: View {
    @StateObject private var viewModel: StudySessionViewModel

    @MainActor
    init(viewModel: StudySessionViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            content
                .padding()
                .navigationTitle("IELTS Flashcards")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        VStack(spacing: 0) {
                            Text("IELTS Flashcards")
                                .font(.headline.weight(.semibold))
                                .foregroundStyle(AppColors.secondary)
                        }
                    }
                    ToolbarItem(placement: .primaryAction) {
                        optionsMenu
                            .foregroundStyle(AppColors.secondary)
                    }
                }
                .toolbar {
                    ToolbarItem(placement: .keyboard) {
                        HStack {
                            Spacer()
                        }
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
                ProgressView("Caricamento carte…")
                    .progressViewStyle(.circular)
                    .tint(AppColors.secondary)
            case let .failed(message):
                errorView(message: message)
            case let .ready(card):
                studyView(card: card)
            case .completed:
                completedView
            }
        }
    }

    private var optionsMenu: some View {
        Menu {
            Section("Livello") {
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
                                    .foregroundStyle(AppColors.primary)
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
                Label("Azzera progressi", systemImage: "arrow.counterclockwise")
            }
        } label: {
            Image(systemName: "line.3.horizontal.decrease.circle")
                .foregroundStyle(AppColors.secondary)
        }
    }

    @ViewBuilder
    private func errorView(message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.title)
                .foregroundStyle(AppColors.primary)
            
            Text("Si è verificato un errore")
                .font(.title3.weight(.semibold))
                .foregroundStyle(AppColors.secondary)
            
            Text(message)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .font(.caption)
            
            Button("Riprova") {
                Task { await viewModel.load() }
            }
            .buttonStyle(.borderedProminent)
            .tint(AppColors.secondary)
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
                    levelName: viewModel.selectedLevelTitle
                )

                SwipeableFlashcardView(
                    card: card,
                    showBack: viewModel.showBack,
                    onToggle: {
                        Haptics.selection()
                        withAnimation(.easeInOut) {
                            viewModel.toggleCard()
                        }
                    },
                    onSwipe: { outcome in
                        withAnimation(.easeIn) {
                            viewModel.review(outcome)
                        }
                    }
                )
                .frame(height: cardHeight)

                Text(viewModel.showBack ? "Swipe: sinistra = Ripeti, su = Buono, destra = Facile." : "Tocca la carta o premi \"Mostra risposta\".")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)

                if !viewModel.showBack {
                    Button("Mostra risposta") {
                        withAnimation(.easeInOut) {
                            viewModel.toggleCard()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(AppColors.reading)
                    .frame(maxWidth: .infinity)
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
                .foregroundStyle(AppColors.speaking)
            
            Text("Tutte le carte sono aggiornate 🎉")
                .font(.title3.weight(.semibold))
                .foregroundStyle(AppColors.secondary)
            
            Text("Torna più tardi oppure azzera i progressi per ricominciare da capo.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .font(.caption)
            
            Button(role: .destructive) {
                withAnimation {
                    viewModel.resetProgress()
                }
            } label: {
                Label("Azzera progressi", systemImage: "arrow.counterclockwise")
            }
            .buttonStyle(.bordered)
            .foregroundStyle(AppColors.primary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }
}

private struct SwipeableFlashcardView: View {
    let card: Flashcard
    let showBack: Bool
    let onToggle: () -> Void
    let onSwipe: (ReviewOutcome) -> Void

    @State private var translation: CGSize = .zero
    @State private var isDragging = false
    @State private var isAnimatingOut = false

    private let horizontalThreshold: CGFloat = 100
    private let verticalThreshold: CGFloat = 100

    var body: some View {
        FlashcardStudyCard(card: card, showBack: showBack)
            .contentShape(Rectangle())
            .offset(translation)
            .rotationEffect(.degrees(Double(translation.width / 15)))
            .scaleEffect(isDragging ? 0.98 : 1.0)
            .overlay(alignment: .topLeading) {
                if showBack && translation.width < -60 {
                    SwipeBadge(text: "Ripeti", color: AppColors.reviewAgain)
                        .padding(16)
                }
            }
            .overlay(alignment: .topTrailing) {
                if showBack && translation.width > 60 {
                    SwipeBadge(text: "Facile", color: AppColors.reviewEasy)
                        .padding(16)
                }
            }
            .overlay(alignment: .top) {
                if showBack && translation.height < -60 {
                    SwipeBadge(text: "Buono", color: AppColors.reviewGood)
                        .padding(.top, 28)
                }
            }
            .gesture(dragGesture)
            .onTapGesture {
                onToggle()
            }
    }

    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                guard showBack, !isAnimatingOut else { return }
                translation = value.translation
                isDragging = true
            }
            .onEnded { value in
                isDragging = false
                guard showBack, !isAnimatingOut else {
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
    static let allLevelsLabel = "Tutti i livelli"

    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var availableLevels: [String] = []
    @Published private(set) var selectedLevel: String
    @Published private(set) var orderedCards: [Flashcard] = []
    @Published private(set) var currentCard: Flashcard?
    @Published var showBack = false

    private let loadCards: () throws -> [Flashcard]
    private let progressStore: FlashcardProgressStore
    private let scheduler: SpacedRepetitionScheduler
    private var allCards: [Flashcard] = []
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
        selectedLevel: String = "Tutti i livelli"
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
            errorMessage = "Impossibile caricare le flashcard. \(error.localizedDescription)"
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

    func toggleCard() {
        guard currentCard != nil else { return }
        showBack.toggle()
    }

    func review(_ outcome: ReviewOutcome) {
        guard let card = currentCard else { return }
        let now = Date()
        let currentProgress = progressById[card.id] ?? FlashcardProgress.new(now: now)
        let updated = scheduler.reviewed(card, current: currentProgress, outcome: outcome, now: now)

        progressById[card.id] = updated
        progressStore.setProgress(updated, for: card)

        showBack = false
        refreshQueue(now: now)
    }

    func resetProgress() {
        progressStore.reset()
        progressById.removeAll()
        showBack = false
        refreshQueue()
    }

    var canReviewCurrentCard: Bool {
        currentCard != nil && showBack
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

    private func configure(with cards: [Flashcard], initialProgress: [String: FlashcardProgress]) {
        allCards = cards
        let normalizedLevels = Set(cards.map { $0.normalizedLevel })
        availableLevels = [Self.allLevelsLabel] + normalizedLevels.sorted { $0.localizedCompare($1) == .orderedAscending }

        let knownIds = Set(cards.map(\.id))
        progressById = initialProgress.reduce(into: [:]) { partialResult, element in
            if knownIds.contains(element.key) {
                partialResult[element.key] = element.value
            }
        }

        if !availableLevels.contains(selectedLevel) {
            selectedLevel = Self.allLevelsLabel
        }

        refreshQueue()
    }

    private func refreshQueue(now: Date = Date()) {
        guard !allCards.isEmpty else {
            orderedCards = []
            currentCard = nil
            return
        }

        let filteredCards: [Flashcard]
        if selectedLevel == Self.allLevelsLabel {
            filteredCards = allCards
        } else {
            filteredCards = allCards.filter { $0.normalizedLevel.caseInsensitiveCompare(selectedLevel) == .orderedSame }
        }

        orderedCards = scheduler.reorder(cards: filteredCards, with: progressById)

        let dueCards = orderedCards.filter { card in
            let dueDate = progressById[card.id]?.dueDate ?? .distantPast
            return dueDate <= now
        }

        currentCard = dueCards.first ?? orderedCards.first
    }
}

private struct StudyHeaderView: View {
    let currentPosition: Int
    let totalCount: Int
    let dueCount: Int
    let levelName: String

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text(levelName)
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(AppColors.secondary)
                    .clipShape(Capsule())

                Spacer()

                if totalCount > 0 {
                    Text("Carta \(currentPosition) di \(totalCount)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            HStack {
                Label("\(dueCount) da ripassare", systemImage: "clock.arrow.circlepath")
                    .font(.caption)
                    .foregroundStyle(AppColors.primary.opacity(0.8))
                    .fontWeight(.medium)
                Spacer()
            }
        }
    }
}

private struct FlashcardStudyCard: View {
    let card: Flashcard
    let showBack: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(card.word.capitalized)
                .font(.largeTitle.weight(.bold))
                .foregroundStyle(AppColors.secondary)

            Text(card.translation)
                .font(.title3)
                .foregroundStyle(AppColors.primary)

            Divider()

            if showBack {
                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Definizione")
                            .font(.headline)
                            .foregroundStyle(AppColors.reading)
                        Text(card.definition)
                            .foregroundStyle(.primary)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Esempio")
                            .font(.headline)
                            .foregroundStyle(AppColors.reading)
                        Text("\u{201C}\(card.example)\u{201D}")
                            .italic()
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                Text("Tocca per visualizzare la definizione e l'esempio.")
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
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.white,
                            Color(red: 248/255, green: 248/255, blue: 255/255)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: AppColors.secondary.opacity(0.1), radius: 12, x: 0, y: 6)
        )
    }
}

private struct StudyActionsView: View {
    let canReview: Bool
    let onAgain: () -> Void
    let onGood: () -> Void
    let onEasy: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            StudyActionButton(
                title: "Ripeti",
                subtitle: "10 min",
                systemImage: "arrow.uturn.backward",
                tint: AppColors.reviewAgain,
                action: onAgain
            )

            StudyActionButton(
                title: "Buono",
                subtitle: "1 giorno",
                systemImage: "checkmark.circle",
                tint: AppColors.reviewGood,
                action: onGood
            )

            StudyActionButton(
                title: "Facile",
                subtitle: "2+ giorni",
                systemImage: "sun.max",
                tint: AppColors.reviewEasy,
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

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ProgressView(
                value: Double(studiedCount),
                total: Double(max(totalCount, 1))
            )
            .tint(AppColors.secondary)

            Text("Avanzamento \(studiedCount)/\(totalCount)")
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
