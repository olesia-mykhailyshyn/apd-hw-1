import Foundation

public enum StudyCategory: String, Codable, CaseIterable {
    case reading, practice, project
}

public enum StudyPlanError: Error, Equatable {
    case blankTitle
    case nonPositiveEstimatedMinutes
    case duplicateID(String)
    case unknownID(String)
}

public struct StudyItem: Codable, Equatable {
    public let id: String
    public let title: String
    public let estimatedMinutes: Int
    public let category: StudyCategory
    public private(set) var isCompleted: Bool

    public init(
        id: String,
        title: String,
        estimatedMinutes: Int,
        category: StudyCategory,
        isCompleted: Bool = false
    ) throws {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedTitle.isEmpty {
            throw StudyPlanError.blankTitle
        }

        if estimatedMinutes <= 0 {
            throw StudyPlanError.nonPositiveEstimatedMinutes
        }

        self.id = id
        self.title = title
        self.estimatedMinutes = estimatedMinutes
        self.category = category
        self.isCompleted = isCompleted
    }
}

public struct StudyPlan: Codable, Equatable {
    public private(set) var items: [StudyItem]

    public init(items: [StudyItem]) throws {
        fatalError("Implement plan validation")
    }

    public static func decode(from data: Data) throws -> StudyPlan {
        fatalError("Implement array decoding")
    }

    public func items(in category: StudyCategory) -> [StudyItem] {
        fatalError("Implement category query")
    }

    public func incompleteMinutes() -> Int {
        fatalError("Implement incomplete-minute query")
    }

    public mutating func markCompleted(id: String) throws {
        fatalError("Implement completion mutation")
    }

    public mutating func importMerging(_ importedItems: [StudyItem]) throws {
        fatalError("Implement optional bonus")
    }
}
