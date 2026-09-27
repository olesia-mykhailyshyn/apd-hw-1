import XCTest
@testable import StudyPlanner

final class StudyPlannerStudentTests: XCTestCase {

    // MARK: - Task 1: validation and errors

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
}
