import Foundation
import UIKit

struct Flashcard: Identifiable, Codable, Hashable {
    static let defaultDeckId = "core"
    static let defaultDeckName = "Vocabolario Base"

    let deckId: String
    let deckName: String
    let deckDescription: String
    let word: String
    let level: String
    let definition: String
    let example: String
    let translation: String

    var id: String {
        let normalizedDeck = deckId.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let normalizedWord = legacyIdentifier
        return "\(normalizedDeck)::\(normalizedWord)"
    }

    var normalizedLevel: String {
        level.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var legacyIdentifier: String {
        word.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    init(
        deckId: String = Flashcard.defaultDeckId,
        deckName: String = Flashcard.defaultDeckName,
        deckDescription: String = "",
        word: String,
        level: String,
        definition: String,
        example: String,
        translation: String
    ) {
        self.deckId = deckId.isEmpty ? Flashcard.defaultDeckId : deckId
        self.deckName = deckName.isEmpty ? Flashcard.defaultDeckName : deckName
        self.deckDescription = deckDescription
        self.word = word
        self.level = level
        self.definition = definition
        self.example = example
        self.translation = translation
    }

    private enum CodingKeys: String, CodingKey {
        case deckId
        case deckName
        case deckDescription
        case word
        case level
        case definition
        case example
        case translation
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let decodedDeckId = try container.decodeIfPresent(String.self, forKey: .deckId)?.trimmingCharacters(in: .whitespacesAndNewlines)
        let decodedDeckName = try container.decodeIfPresent(String.self, forKey: .deckName)?.trimmingCharacters(in: .whitespacesAndNewlines)
        deckDescription = try container.decodeIfPresent(String.self, forKey: .deckDescription) ?? ""
        deckId = decodedDeckId?.isEmpty == false ? decodedDeckId! : Flashcard.defaultDeckId
        deckName = decodedDeckName?.isEmpty == false ? decodedDeckName! : Flashcard.defaultDeckName
        word = try container.decode(String.self, forKey: .word)
        level = try container.decode(String.self, forKey: .level)
        definition = try container.decode(String.self, forKey: .definition)
        example = try container.decode(String.self, forKey: .example)
        translation = try container.decode(String.self, forKey: .translation)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(deckId, forKey: .deckId)
        try container.encode(deckName, forKey: .deckName)
        try container.encode(deckDescription, forKey: .deckDescription)
        try container.encode(word, forKey: .word)
        try container.encode(level, forKey: .level)
        try container.encode(definition, forKey: .definition)
        try container.encode(example, forKey: .example)
        try container.encode(translation, forKey: .translation)
    }
}

struct FlashcardProgress: Codable, Equatable {
    var easeFactor: Double
    var interval: TimeInterval
    var dueDate: Date
    var repetitions: Int
    var lastReview: Date

    static func new(now: Date) -> FlashcardProgress {
        FlashcardProgress(
            easeFactor: 2.5,
            interval: 0,
            dueDate: now,
            repetitions: 0,
            lastReview: now
        )
    }
}

enum ReviewOutcome {
    case again
    case good
    case easy
}

struct SpacedRepetitionScheduler {
    private let minimumEaseFactor: Double = 1.3

    func reorder(cards: [Flashcard], with progress: [String: FlashcardProgress]) -> [Flashcard] {
        cards.sorted { lhs, rhs in
            let leftDue = progress[lhs.id]?.dueDate ?? .distantPast
            let rightDue = progress[rhs.id]?.dueDate ?? .distantPast

            if leftDue == rightDue {
                return lhs.word.localizedCompare(rhs.word) == .orderedAscending
            }
            return leftDue < rightDue
        }
    }

    func reviewed(_ card: Flashcard, current: FlashcardProgress, outcome: ReviewOutcome, now: Date = .init()) -> FlashcardProgress {
        var updated = current

        switch outcome {
        case .again:
            updated.repetitions = 0
            updated.interval = 10 * 60 // 10 minutes
            updated.easeFactor = max(minimumEaseFactor, updated.easeFactor - 0.2)
        case .good:
            updated.repetitions += 1
            if updated.repetitions == 1 {
                updated.interval = 24 * 60 * 60 // 1 day
            } else if updated.repetitions == 2 && updated.interval < 24 * 60 * 60 {
                updated.interval = 3 * 24 * 60 * 60 // 3 days
            } else {
                updated.interval *= updated.easeFactor
            }
            updated.easeFactor = max(minimumEaseFactor, updated.easeFactor - 0.05)
        case .easy:
            updated.repetitions += 1
            if updated.repetitions == 1 {
                updated.interval = 2 * 24 * 60 * 60 // 2 days
            } else if updated.repetitions == 2 && updated.interval < 2 * 24 * 60 * 60 {
                updated.interval = 4 * 24 * 60 * 60 // 4 days
            } else {
                updated.interval *= (updated.easeFactor + 0.2)
            }
            updated.easeFactor = max(minimumEaseFactor, updated.easeFactor + 0.1)
        }

        updated.lastReview = now
        updated.dueDate = now.addingTimeInterval(updated.interval)

        return updated
    }
}

final class FlashcardProgressStore {
    private let storageKey = "flashcard-progress"
    private let defaults: UserDefaults
    private var cache: [String: FlashcardProgress]
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: storageKey),
           let decoded = try? decoder.decode([String: FlashcardProgress].self, from: data) {
            cache = decoded
        } else {
            cache = [:]
        }
    }

    func progress(for card: Flashcard, now: Date = .init()) -> FlashcardProgress {
        cache[card.id] ?? FlashcardProgress.new(now: now)
    }

    func setProgress(_ progress: FlashcardProgress, for card: Flashcard) {
        cache[card.id] = progress
        persist()
    }

    func allProgress() -> [String: FlashcardProgress] {
        cache
    }

    func reset() {
        cache.removeAll()
        defaults.removeObject(forKey: storageKey)
    }

    private func persist() {
        if let data = try? encoder.encode(cache) {
            defaults.set(data, forKey: storageKey)
        }
    }
}

struct VocabularyRepository {
    enum RepositoryError: Error {
        case missingResource
    }

    private let decoder: JSONDecoder

    init(decoder: JSONDecoder = JSONDecoder()) {
        self.decoder = decoder
    }

    func loadAllCards() throws -> [Flashcard] {
        if let asset = NSDataAsset(name: "Vocabulary") {
            return try decoder.decode([Flashcard].self, from: asset.data)
        }

        guard let url = Bundle.main.url(forResource: "vocabulary", withExtension: "json", subdirectory: "Data") ?? Bundle.main.url(forResource: "vocabulary", withExtension: "json") else {
            throw RepositoryError.missingResource
        }
        let data = try Data(contentsOf: url)
        return try decoder.decode([Flashcard].self, from: data)
    }
}
