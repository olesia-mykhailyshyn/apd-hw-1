// Demo program: runs every StudyPlanner feature and prints the results,
// so you can see how the library behaves outside of the tests.

import Foundation
import StudyPlanner

func item(_ id: String, _ title: String, _ minutes: Int, _ category: StudyCategory) throws -> StudyItem {
    try StudyItem(id: id, title: title, estimatedMinutes: minutes, category: category)
}

func show(_ plan: StudyPlan) {
    for item in plan.items {
        let mark = item.isCompleted ? "[x]" : "[ ]"
        print("  \(mark) \(item.id): \(item.title), \(item.estimatedMinutes) min, \(item.category.rawValue)")
    }
}

func attempt(_ description: String, _ action: () throws -> Void) {
    do {
        try action()
        print("  OK     \(description)")
    } catch {
        print("  ERROR  \(description) -> \(error)")
    }
}

func decodeItem(_ json: String) throws {
    _ = try JSONDecoder().decode(StudyItem.self, from: Data(json.utf8))
}

do {
    print("\n=== Task 1: validation ===")
    attempt("valid item") { _ = try item("ok", "Read", 30, .reading) }
    attempt("blank title") { _ = try item("x", "  \n", 30, .reading) }
    attempt("zero minutes") { _ = try item("x", "Read", 0, .reading) }
    attempt("blank title and zero minutes") { _ = try item("x", "", 0, .reading) }

    print("\n=== Task 3: duplicates and sorting ===")
    var plan = try StudyPlan(items: [
        try item("r1", "Read chapter", 45, .reading),
        try item("p1", "Practice drills", 30, .practice),
        try item("j1", "Build milestone", 90, .project),
        try item("r0", "Read chapter", 20, .reading)
    ])
    show(plan)
    attempt("plan with duplicate id") {
        _ = try StudyPlan(items: [try item("a", "A", 10, .reading), try item("a", "B", 10, .reading)])
    }

    print("\n=== Task 4: queries and completion ===")
    print("  reading: \(plan.items(in: .reading).map(\.id)), incomplete minutes: \(plan.incompleteMinutes())")
    attempt("complete r1") { try plan.markCompleted(id: "r1") }
    attempt("complete r1 again") { try plan.markCompleted(id: "r1") }
    attempt("complete unknown id") { try plan.markCompleted(id: "banana") }
    print("  incomplete minutes: \(plan.incompleteMinutes())")
    show(plan)

    print("\n=== Task 2: decoding JSON ===")
    let array = #"[{ "id": "b", "title": "Second", "estimatedMinutes": 20, "category": "practice" },"#
        + #" { "id": "a", "title": "First", "estimatedMinutes": 10, "category": "reading" }]"#
    show(try StudyPlan.decode(from: Data(array.utf8)))
    let keyed = #"{ "items": [{ "id": "k", "title": "Keyed", "estimatedMinutes": 15, "category": "project" }] }"#
    show(try JSONDecoder().decode(StudyPlan.self, from: Data(keyed.utf8)))
    attempt("decode blank title") {
        try decodeItem(#"{ "id": "x", "title": " ", "estimatedMinutes": 10, "category": "reading" }"#)
    }
    attempt("decode unknown category") {
        try decodeItem(#"{ "id": "x", "title": "A", "estimatedMinutes": 10, "category": "banana" }"#)
    }

    print("\n=== Bonus: importMerging ===")
    attempt("replace j1, add zz and aa") {
        try plan.importMerging([
            try item("j1", "Build milestone v2", 120, .project),
            try item("zz", "Watch talk", 25, .reading),
            try item("aa", "Read article", 15, .reading)
        ])
    }
    show(plan)
    let before = plan
    attempt("import with duplicate incoming id") {
        try plan.importMerging([try item("dup", "One", 5, .reading), try item("dup", "Two", 5, .reading)])
    }
    print("  plan unchanged after failed import: \(plan == before)")
} catch {
    print("Unexpected error: \(error)")
}
