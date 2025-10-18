import Foundation
import Testing
@testable import IELTS_flashcards

struct IELTS_flashcardsTests {

    @Test func schedulerAdjustsIntervals() throws {
        let scheduler = SpacedRepetitionScheduler()
        let card = Flashcard(
            word: "analyze",
            level: "Base",
            definition: "To examine something in detail.",
            example: "Analyze the data carefully.",
            translation: "analizzare"
        )
        let now = Date()
        let initialProgress = FlashcardProgress.new(now: now)

        let againProgress = scheduler.reviewed(card, current: initialProgress, outcome: .again, now: now)
        let goodProgress = scheduler.reviewed(card, current: initialProgress, outcome: .good, now: now)
        let easyProgress = scheduler.reviewed(card, current: initialProgress, outcome: .easy, now: now)

        #expect(againProgress.interval == 10 * 60)
        #expect(abs(againProgress.dueDate.timeIntervalSince(now) - 600) < 0.5)

        #expect(goodProgress.interval == 24 * 60 * 60)
        #expect(abs(goodProgress.dueDate.timeIntervalSince(now) - 86_400) < 0.5)

        #expect(easyProgress.interval == 2 * 24 * 60 * 60)
        #expect(abs(easyProgress.dueDate.timeIntervalSince(now) - 172_800) < 0.5)
    }

    @MainActor
    @Test func viewModelFiltersAndSchedulesCards() async throws {
        let suite = "IELTSFlashcardsTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        defer { defaults.removePersistentDomain(forName: suite) }

        let cards = [
            Flashcard(
                word: "analyze",
                level: "Base",
                definition: "To examine something in detail for explanation and interpretation.",
                example: "Students must analyze data before writing conclusions.",
                translation: "analizzare"
            ),
            Flashcard(
                deckId: "graphs",
                deckName: "Vocabolario Grafici",
                word: "debate",
                level: "Avanzato",
                definition: "A formal discussion on a particular matter.",
                example: "Candidates debate policies before the election.",
                translation: "dibattere"
            )
        ]

        let progressStore = FlashcardProgressStore(defaults: defaults)
        let viewModel = StudySessionViewModel(
            loadCards: { cards },
            progressStore: progressStore,
            scheduler: SpacedRepetitionScheduler(),
            initialCards: cards,
            initialProgress: [:]
        )

        #expect(viewModel.availableDecks.count == 2)
        #expect(viewModel.selectedDeckId == nil)
        #expect(viewModel.selectedDeckTitle == StudySessionViewModel.allDecksLabel)
        #expect(viewModel.totalCount == 2)
        #expect(viewModel.currentCard?.word == "analyze")
        #expect(viewModel.dueCount == 2)

        if let graphsDeck = viewModel.availableDecks.first(where: { $0.id == "graphs" }) {
            viewModel.setDeck(id: graphsDeck.id)
            #expect(viewModel.selectedDeckTitle == graphsDeck.name)
            #expect(viewModel.totalCount == 1)
            #expect(viewModel.currentCard?.word == "debate")
        } else {
            Issue.record("Missing graphs deck in availableDecks.")
        }

        viewModel.setDeck(id: nil)
        #expect(viewModel.totalCount == 2)
        #expect(viewModel.selectedDeckTitle == StudySessionViewModel.allDecksLabel)

        viewModel.setLevel("Avanzato")
        #expect(viewModel.totalCount == 1)
        #expect(viewModel.currentCard?.word == "debate")

        viewModel.setLevel(StudySessionViewModel.allLevelsLabel)
        viewModel.toggleCard()
        viewModel.review(.good)

        let storedProgress = progressStore.allProgress()
        #expect(storedProgress[cards[0].id]?.repetitions == 1)
        #expect(viewModel.showBack == false)
        #expect(viewModel.dueCount == 1)

        viewModel.resetProgress()
        #expect(progressStore.allProgress().isEmpty)
    }

    @Test func vocabularyDatasetIsValid() throws {
        let testsDirectory = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
        let projectRoot = testsDirectory.deletingLastPathComponent()

        let dataURL = projectRoot
            .appendingPathComponent("IELTS flashcards")
            .appendingPathComponent("Data")
            .appendingPathComponent("vocabulary.json")

        let assetURL = projectRoot
            .appendingPathComponent("IELTS flashcards")
            .appendingPathComponent("Assets.xcassets")
            .appendingPathComponent("Vocabulary.dataset")
            .appendingPathComponent("vocabulary.json")

        let decoder = JSONDecoder()
        let data = try Data(contentsOf: dataURL)
        let cards = try decoder.decode([Flashcard].self, from: data)

        #expect(!cards.isEmpty, "Vocabulary dataset must contain entries.")

        var seenCards = Set<String>()
        var decks: [String: String] = [:]

        for card in cards {
            let trimmedWord = card.word.trimmingCharacters(in: .whitespacesAndNewlines)
            let normalizedWord = trimmedWord.lowercased()
            let deckKey = card.deckId.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            let compositeKey = "\(deckKey)::\(normalizedWord)"

            #expect(!trimmedWord.isEmpty, "Word must not be empty.")
            #expect(!card.level.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, "Level must not be empty.")
            #expect(!card.definition.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, "Definition must not be empty.")
            #expect(!card.example.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, "Example must not be empty.")
            #expect(!card.translation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, "Translation must not be empty.")
            #expect(!card.deckId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, "Deck ID must not be empty.")
            #expect(!card.deckName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, "Deck name must not be empty.")
            #expect(!seenCards.contains(compositeKey), "Duplicate entry found for '\(card.word)' in deck '\(card.deckName)'.")

            if let existingName = decks[deckKey] {
                #expect(existingName == card.deckName, "Deck name mismatch for id '\(card.deckId)'.")
            } else {
                decks[deckKey] = card.deckName
            }

            seenCards.insert(compositeKey)

            let exampleContainsWord = card.example.range(
                of: trimmedWord,
                options: [.caseInsensitive, .diacriticInsensitive]
            ) != nil
            #expect(exampleContainsWord, "Example must include the word '\(card.word)'.")
        }

        let assetData = try Data(contentsOf: assetURL)
        let assetCards = try decoder.decode([Flashcard].self, from: assetData)

        #expect(cards == assetCards, "Asset catalog dataset must match Data/vocabulary.json.")
    }

}
