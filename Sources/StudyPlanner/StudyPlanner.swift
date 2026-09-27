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

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let id = try container.decode(String.self, forKey: .id)
        let title = try container.decode(String.self, forKey: .title)
        let estimatedMinutes = try container.decode(Int.self, forKey: .estimatedMinutes)
        let category = try container.decode(StudyCategory.self, forKey: .category)
        let isCompleted = try container.decodeIfPresent(Bool.self, forKey: .isCompleted) ?? false

        try self.init(
            id: id,
            title: title,
            estimatedMinutes: estimatedMinutes,
            category: category,
            isCompleted: isCompleted
        )
    }

    mutating func markAsCompleted() {
        isCompleted = true
    }
}

public struct StudyPlan: Codable, Equatable {
    public private(set) var items: [StudyItem]

    public init(items: [StudyItem]) throws {
        try Self.rejectDuplicateIDs(in: items)

        self.items = items.sorted { first, second in
            (first.title, first.id) < (second.title, second.id)
        }
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let items = try container.decode([StudyItem].self, forKey: .items)
        try self.init(items: items)
    }

    public static func decode(from data: Data) throws -> StudyPlan {
        let items = try JSONDecoder().decode([StudyItem].self, from: data)
        return try StudyPlan(items: items)
    }

    public func items(in category: StudyCategory) -> [StudyItem] {
        items.filter { item in
            item.category == category
        }
    }

    public func incompleteMinutes() -> Int {
        var total = 0
        for item in items where !item.isCompleted {
            total += item.estimatedMinutes
        }
        return total
    }

    public mutating func markCompleted(id: String) throws {
        guard let index = items.firstIndex(where: { $0.id == id }) else {
            throw StudyPlanError.unknownID(id)
        }
        items[index].markAsCompleted()
    }

    public mutating func importMerging(_ importedItems: [StudyItem]) throws {
        try Self.rejectDuplicateIDs(in: importedItems)

        let importedByID = Dictionary(uniqueKeysWithValues: importedItems.map { ($0.id, $0) })
        let existingIDs = Set(items.map(\.id))

        let updatedItems = items.map { item in
            importedByID[item.id] ?? item
        }

        let newItems = importedItems
            .filter { !existingIDs.contains($0.id) }
            .sorted { $0.id < $1.id }

        items = updatedItems + newItems
    }

    private static func rejectDuplicateIDs(in items: [StudyItem]) throws {
        var seenIDs = Set<String>()
        for item in items {
            if seenIDs.contains(item.id) {
                throw StudyPlanError.duplicateID(item.id)
            }
            seenIDs.insert(item.id)
        }
    }
}
