import XCTest
import StudyPlanner

final class StudyPlannerStudentTests: XCTestCase {

    func testWhitespaceOnlyTitleThrowsBlankTitle() {
        XCTAssertThrowsError(
            try StudyItem(id: "x", title: " \t\n ", estimatedMinutes: 10, category: .reading)
        ) { error in
            XCTAssertEqual(error as? StudyPlanError, .blankTitle)
        }
    }

    func testZeroAndNegativeMinutesThrowNonPositiveMinutes() {
        for minutes in [0, -1, -60] {
            XCTAssertThrowsError(
                try StudyItem(id: "x", title: "A", estimatedMinutes: minutes, category: .reading)
            ) { error in
                XCTAssertEqual(error as? StudyPlanError, .nonPositiveEstimatedMinutes)
            }
        }
    }

    func testBlankTitleIsReportedBeforeBadMinutes() {
        XCTAssertThrowsError(
            try StudyItem(id: "x", title: "", estimatedMinutes: 0, category: .project)
        ) { error in
            XCTAssertEqual(error as? StudyPlanError, .blankTitle)
        }
    }

    func testValidItemKeepsOriginalTitleAndAllFields() throws {
        let item = try StudyItem(
            id: "p-1",
            title: "  Build app  ",
            estimatedMinutes: 1,
            category: .project,
            isCompleted: true
        )

        XCTAssertEqual(item.id, "p-1")
        XCTAssertEqual(item.title, "  Build app  ")
        XCTAssertEqual(item.estimatedMinutes, 1)
        XCTAssertEqual(item.category, .project)
        XCTAssertTrue(item.isCompleted)
    }

    private func decodeItem(_ json: String) throws -> StudyItem {
        try JSONDecoder().decode(StudyItem.self, from: Data(json.utf8))
    }

    func testDecodingItemWithBlankTitleThrowsBlankTitle() {
        let json = """
        { "id": "x", "title": "  ", "estimatedMinutes": 10, "category": "reading", "isCompleted": false }
        """

        XCTAssertThrowsError(try decodeItem(json)) { error in
            XCTAssertEqual(error as? StudyPlanError, .blankTitle)
        }
    }

    func testDecodingItemWithZeroMinutesThrowsNonPositiveMinutes() {
        let json = """
        { "id": "x", "title": "A", "estimatedMinutes": 0, "category": "reading", "isCompleted": false }
        """

        XCTAssertThrowsError(try decodeItem(json)) { error in
            XCTAssertEqual(error as? StudyPlanError, .nonPositiveEstimatedMinutes)
        }
    }

    func testDecodingValidItemReadsAllFields() throws {
        let json = """
        { "id": "p-1", "title": "Build", "estimatedMinutes": 90, "category": "project", "isCompleted": true }
        """

        let item = try decodeItem(json)

        XCTAssertEqual(item.id, "p-1")
        XCTAssertEqual(item.title, "Build")
        XCTAssertEqual(item.estimatedMinutes, 90)
        XCTAssertEqual(item.category, .project)
        XCTAssertTrue(item.isCompleted)
    }

    func testDecodingItemWithoutIsCompletedDefaultsToFalse() throws {
        let json = """
        { "id": "r-1", "title": "Read", "estimatedMinutes": 20, "category": "reading" }
        """

        let item = try decodeItem(json)

        XCTAssertFalse(item.isCompleted)
    }

    func testDecodingItemWithUnknownCategoryFails() {
        let json = """
        { "id": "x", "title": "A", "estimatedMinutes": 10, "category": "banana", "isCompleted": false }
        """

        XCTAssertThrowsError(try decodeItem(json)) { error in
            XCTAssertTrue(error is DecodingError)
        }
    }

    func testDecodingKeyedPlanValidatesAndSortsItems() throws {
        let json = """
        {
          "items": [
            { "id": "b", "title": "Second", "estimatedMinutes": 20, "category": "practice", "isCompleted": false },
            { "id": "a", "title": "First", "estimatedMinutes": 10, "category": "reading", "isCompleted": false }
          ]
        }
        """

        let plan = try JSONDecoder().decode(StudyPlan.self, from: Data(json.utf8))

        XCTAssertEqual(plan.items.map(\.id), ["a", "b"])
    }

    func testDecodingKeyedPlanRejectsInvalidItem() {
        let json = """
        {
          "items": [
            { "id": "a", "title": "A", "estimatedMinutes": -1, "category": "reading", "isCompleted": false }
          ]
        }
        """

        XCTAssertThrowsError(try JSONDecoder().decode(StudyPlan.self, from: Data(json.utf8))) { error in
            XCTAssertEqual(error as? StudyPlanError, .nonPositiveEstimatedMinutes)
        }
    }

    func testDecodingTopLevelArrayFixture() throws {
        let url = try XCTUnwrap(
            Bundle.module.url(forResource: "study-items", withExtension: "json", subdirectory: "Fixtures")
        )
        let data = try Data(contentsOf: url)

        let plan = try StudyPlan.decode(from: data)

        XCTAssertEqual(
            plan.items.map(\.id),
            ["planner-milestone", "collections-drill", "swift-chapter-1"]
        )
    }

    func testDecodingTopLevelArrayRejectsDuplicateIDs() {
        let json = """
        [
          { "id": "a", "title": "A", "estimatedMinutes": 10, "category": "reading", "isCompleted": false },
          { "id": "a", "title": "B", "estimatedMinutes": 20, "category": "practice", "isCompleted": false }
        ]
        """

        XCTAssertThrowsError(try StudyPlan.decode(from: Data(json.utf8))) { error in
            XCTAssertEqual(error as? StudyPlanError, .duplicateID("a"))
        }
    }

    func testSavedPlanLoadsBackWithoutLosingData() throws {
        var plan = try makeSamplePlan()
        try plan.markCompleted(id: "r1")

        let saved = try JSONEncoder().encode(plan)
        let loaded = try JSONDecoder().decode(StudyPlan.self, from: saved)

        XCTAssertEqual(loaded, plan)
        XCTAssertEqual(loaded.incompleteMinutes(), plan.incompleteMinutes())
    }

    private func makeItem(
        _ id: String,
        _ title: String,
        minutes: Int = 10,
        category: StudyCategory = .reading,
        completed: Bool = false
    ) throws -> StudyItem {
        try StudyItem(
            id: id,
            title: title,
            estimatedMinutes: minutes,
            category: category,
            isCompleted: completed
        )
    }

    func testFirstRepeatedIDIsReported() throws {
        let items = [
            try makeItem("a", "A"),
            try makeItem("b", "B"),
            try makeItem("b", "B again"),
            try makeItem("a", "A again")
        ]

        XCTAssertThrowsError(try StudyPlan(items: items)) { error in
            XCTAssertEqual(error as? StudyPlanError, .duplicateID("b"))
        }
    }

    func testSameTitlesAreOrderedByID() throws {
        let plan = try StudyPlan(items: [
            try makeItem("z", "Read"),
            try makeItem("m", "Alpha"),
            try makeItem("a", "Read")
        ])

        XCTAssertEqual(plan.items.map(\.id), ["m", "a", "z"])
    }

    private func makeSamplePlan() throws -> StudyPlan {
        try StudyPlan(items: [
            try makeItem("r1", "Read chapter", minutes: 45, category: .reading),
            try makeItem("p1", "Practice drills", minutes: 30, category: .practice, completed: true),
            try makeItem("r2", "Read article", minutes: 15, category: .reading),
            try makeItem("j1", "Project milestone", minutes: 90, category: .project)
        ])
    }

    func testItemsInCategoryReturnsOnlyThatCategoryInPlanOrder() throws {
        let plan = try makeSamplePlan()

        XCTAssertEqual(plan.items(in: .reading).map(\.id), ["r2", "r1"])
        XCTAssertEqual(plan.items(in: .project).map(\.id), ["j1"])
    }

    func testItemsInCategoryWithNoMatchesIsEmpty() throws {
        let plan = try StudyPlan(items: [try makeItem("r1", "Read", category: .reading)])

        XCTAssertEqual(plan.items(in: .project), [])
    }

    func testIncompleteMinutesSkipsCompletedItems() throws {
        let plan = try makeSamplePlan()

        XCTAssertEqual(plan.incompleteMinutes(), 45 + 15 + 90)
        XCTAssertEqual(try StudyPlan(items: []).incompleteMinutes(), 0)
    }

    func testMarkCompletedWithUnknownIDThrowsAndKeepsPlan() throws {
        var plan = try makeSamplePlan()
        let before = plan

        XCTAssertThrowsError(try plan.markCompleted(id: "missing")) { error in
            XCTAssertEqual(error as? StudyPlanError, .unknownID("missing"))
        }
        XCTAssertEqual(plan, before)
    }

    func testMarkCompletedTwiceIsIdempotent() throws {
        var plan = try makeSamplePlan()

        try plan.markCompleted(id: "r1")
        let afterFirst = plan
        try plan.markCompleted(id: "r1")

        XCTAssertEqual(plan, afterFirst)
        XCTAssertEqual(plan.incompleteMinutes(), 15 + 90)
        XCTAssertTrue(try XCTUnwrap(plan.items.first { $0.id == "r1" }).isCompleted)
    }

    func testImportWithDuplicateIncomingIDsThrowsAndKeepsPlan() throws {
        var plan = try makeSamplePlan()
        let before = plan

        let incoming = [
            try makeItem("new", "New"),
            try makeItem("r1", "Read chapter v2"),
            try makeItem("new", "New again")
        ]

        XCTAssertThrowsError(try plan.importMerging(incoming)) { error in
            XCTAssertEqual(error as? StudyPlanError, .duplicateID("new"))
        }
        XCTAssertEqual(plan, before)
    }

    func testImportReplacesExistingIDAtItsCurrentPosition() throws {
        var plan = try makeSamplePlan()
        let positionBefore = try XCTUnwrap(plan.items.firstIndex { $0.id == "p1" })

        let replacement = try makeItem("p1", "Zzz practice", minutes: 5, category: .practice)
        try plan.importMerging([replacement])

        XCTAssertEqual(plan.items.count, 4)
        XCTAssertEqual(plan.items[positionBefore], replacement)
        XCTAssertFalse(plan.items[positionBefore].isCompleted)
    }

    func testImportAppendsNewIDsInAscendingIDOrder() throws {
        var plan = try makeSamplePlan()
        let idsBefore = plan.items.map(\.id)

        try plan.importMerging([
            try makeItem("zeta", "A title"),
            try makeItem("alpha", "Z title"),
            try makeItem("mid", "M title")
        ])

        XCTAssertEqual(plan.items.map(\.id), idsBefore + ["alpha", "mid", "zeta"])
    }

    func testImportMixesReplacementsAndNewItems() throws {
        var plan = try makeSamplePlan()
        let idsBefore = plan.items.map(\.id)

        try plan.importMerging([
            try makeItem("d", "Watch talk", minutes: 20),
            try makeItem("j1", "Project v2", minutes: 120, category: .project),
            try makeItem("b", "Read article 2", minutes: 15)
        ])

        XCTAssertEqual(plan.items.map(\.id), idsBefore + ["b", "d"])
        let project = try XCTUnwrap(plan.items.first { $0.id == "j1" })
        XCTAssertEqual(project.estimatedMinutes, 120)
    }

    func testImportOfEmptyListChangesNothing() throws {
        var plan = try makeSamplePlan()
        let before = plan

        try plan.importMerging([])

        XCTAssertEqual(plan, before)
    }
}
