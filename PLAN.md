# Plan

## Scope

The goal of this homework is to make the StudyPlanner work and be reliable. The program keeps a list of study tasks. Each task has an id, a title, an estimated time in minutes, a category (reading, practice or project) and a completed flag.

The template already had all public types and method signatures. Every method body was a `fatalError`, so the public tests crashed right away. My job was to replace those bodies with real logic.

What I implemented:

1. Validation when a study item is created.
2. Safe JSON decoding for one item, for a plan in the `{"items": [...]}` form, and for a plan given as a plain JSON array.
3. Duplicate ID check and stable sorting when a plan is created.
4. Category query, total of incomplete minutes, and marking an item as completed.
5. The optional bonus: `importMerging`.

What I did not change:

- No public signature was changed. I only filled in method bodies.
- I added two `public init(from decoder:)` methods. The types were already `Codable`, so this does not change the API. These methods replace the automatic decoder, which would skip validation.
- I added one small internal helper, `markAsCompleted()`, inside `StudyItem`. It is not public, so users of the library cannot see it.
- The supplied public tests, the fixture file and `Package.swift` are exactly as in the template. I checked this with `git diff` against the template commit.

My own tests are in a separate file, `Tests/StudyPlannerTests/StudyPlannerStudentTests.swift`, so the starter tests stay untouched.

## Acceptance criteria

I wrote the requirements as user stories first, then as acceptance criteria. The stories follow INVEST: each one is independent, small, testable and gives value to the user. The criteria use the Given / When / Then form. Every criterion has at least one test.

Story 1. Validation.
As a student, I want the planner to refuse tasks with an empty title or with zero or negative minutes, so that my plan never contains broken tasks.

- Given a title that is empty or only spaces, tabs or new lines, when I create an item, then I get `blankTitle`.
- Given 0 or a negative number of minutes, when I create an item, then I get `nonPositiveEstimatedMinutes`.
- Given both a blank title and bad minutes, when I create an item, then I get `blankTitle`, because the title is checked first.
- Given valid data, when I create an item, then all five fields are stored as given and the item is not completed by default.

Story 2. Loading from JSON.
As a student, I want to load my plan from a JSON file, so that I do not have to type it again, and broken data is rejected the same way as in the app.

- Given a JSON item with a blank title or bad minutes, when it is decoded, then I get the same error as in Story 1.
- Given a JSON item without `isCompleted`, when it is decoded, then the item is not completed.
- Given a JSON item with an unknown category, when it is decoded, then decoding fails.
- Given a JSON object `{"items": [...]}`, when it is decoded as a plan, then every item is validated and the plan is sorted.
- Given a plain JSON array like the fixture file, when I call `StudyPlan.decode(from:)`, then I get a valid sorted plan.
- Given a plan that was saved to JSON, when I load it back, then it is exactly the same plan.

Story 3. Duplicates and order.
As a student, I want every task to have a unique ID and the list to always be in the same order, so that I can find tasks easily and the result is predictable.

- Given a list where an ID appears twice, when I create a plan, then I get `duplicateID` with the first ID that repeats.
- Given any list, when I create a plan, then items are sorted by title, and items with the same title are sorted by ID.

Story 4. Queries and completion.
As a student, I want to see tasks of one category, see how many minutes are left, and tick tasks as done, so that I know what I still have to do.

- Given a plan, when I ask for one category, then I get only those items, in plan order, or an empty list.
- Given a plan, when I ask for incomplete minutes, then I get the sum of minutes of items that are not completed. An empty plan gives 0.
- Given an ID that is not in the plan, when I mark it completed, then I get `unknownID` and the plan does not change.
- Given an item that is already completed, when I mark it completed again, then nothing changes and there is no error.

Story 5. Import (bonus).
As a student, I want to merge an updated list into my plan, for example from another device, so that changed tasks are updated and new tasks are added without breaking my plan.

- Given incoming items where an ID appears twice, when I import, then I get `duplicateID` and the plan does not change at all.
- Given an incoming item with an ID that is already in the plan, when I import, then it replaces the old item at the same position.
- Given incoming items with new IDs, when I import, then they are added at the end, sorted by ID.
- Given an import that fails, then the plan stays exactly as it was before (the import is atomic).

## Implementation steps

I worked in small steps, one task at a time. In each step the code and the tests for that rule were written together, and I ran the tests before going to the next step.

Step 1. StudyItem validation.
Files: `Sources/StudyPlanner/StudyPlanner.swift`, new file `Tests/StudyPlannerTests/StudyPlannerStudentTests.swift`.
I replaced the `fatalError` in `StudyItem.init` with two checks. First I trim spaces and new lines from the title and throw `blankTitle` if nothing is left. Then I throw `nonPositiveEstimatedMinutes` if minutes are 0 or less. The order of the checks gives the title-before-minutes rule. The title is stored as given, the trimmed version is only used for the check. At first the code used `guard`. I changed it to a simple `if`, because it reads without a double negation. I added 4 tests.

Step 2. Safe JSON decoding for one item.
Files: `StudyPlanner.swift`, student tests.
Swift can decode `Codable` types by itself, but the automatic decoder writes the fields directly and skips my validation. So I wrote my own `StudyItem.init(from:)`. It reads the five fields from JSON and passes them to the normal `init`, so the same checks run. `isCompleted` is read with `decodeIfPresent` and becomes `false` if the field is missing. I added 3 tests.

Step 3. Creating a plan and decoding a plan.
Files: `StudyPlanner.swift`, student tests.
Decoding a plan needs `StudyPlan.init(items:)`, so I did this part of task 3 here. The init goes through the items, remembers seen IDs in a `Set`, and throws `duplicateID` on the first ID that comes again. Then it sorts by title and then by ID. After that I added `StudyPlan.init(from:)` for the `{"items": [...]}` form and filled in `StudyPlan.decode(from:)` for the plain array form. Both go through `init(items:)`. I added 4 tests, one of them uses the fixture file `study-items.json`.

Step 4. Tests for duplicates and sorting.
Files: student tests.
I added a test with several duplicates (`a, b, b, a` must report `b`) and a test with two items that have the same title, to check that the ID decides the order.

Step 5. Queries and completion.
Files: `StudyPlanner.swift`, student tests.
`items(in:)` uses `filter`. `incompleteMinutes()` adds up minutes of items that are not completed. `markCompleted(id:)` finds the item by ID, throws `unknownID` if it is not found, and sets the flag. Setting the flag again changes nothing, so the method is idempotent. Here the compiler showed an error: `'isCompleted' setter is inaccessible`. The reason is that `private(set)` allows writing only inside `StudyItem` itself, not inside `StudyPlan`. I fixed it with a small internal method `markAsCompleted()` inside `StudyItem`, so I did not have to change the public declaration. After this step all three public tests passed for the first time. I added 5 tests.

Step 6. Bonus: importMerging.
Files: `StudyPlanner.swift`, student tests.
First the method checks the incoming items for duplicate IDs. I moved the duplicate check into one private function, `rejectDuplicateIDs`, and now both `init(items:)` and `importMerging` use it. My first version used a loop over a copy of the list. It worked, but it searched the whole list for every incoming item. I rewrote it in a simpler way: a dictionary of incoming items by ID, `map` to replace existing items in place, `filter` and `sorted` to get the new items, and one assignment at the end. Because nothing is written to the plan until the last line, a failed import cannot leave the plan half changed. I added 5 tests. They passed with both versions without any change, which shows the rewrite kept the same behavior.

Step 7. Extra tests and small clean-ups.
Files: `StudyPlanner.swift`, student tests.
I added tests for JSON without `isCompleted` and for an unknown category. I replaced the sort code with a tuple comparison, `(title, id) < (title, id)`, which does the same thing in one line. I changed the student test file from `@testable import` to a normal `import`, so my tests can only use the public API, the same as any user of the library. Last, I added a test that saves a plan to JSON and loads it back, to check that nothing is lost.

Step 8. Demo program.
Files: new folder `Demo/`.
I added a small separate package with a `main.swift` that calls every feature and prints the results. I put it in its own package so the graded `Package.swift` stays unchanged.

## Risks

Some parts of the task can be read in more than one way. I chose the most natural reading and wrote a test for each choice, so the behavior is clear.

1. Which duplicate is "first". For the IDs `a, b, b, a` my code reports `b`, because it is the first ID that shows up a second time while going through the list. Another reading would be `a`, the first ID in the list that has a copy somewhere. I chose the first one because it stops at the first problem it sees.

2. Sorting and letter case. Titles are compared with the normal Swift `<` for strings. This is case-sensitive, so `"Zebra"` comes before `"apple"`. The task only says "title then ID", so I kept the simple comparison. A locale-aware sort would give a different order and could break hidden tests.

3. The title is not trimmed when stored. Trimming is only used to check if a title is blank. `"  Read  "` is stored as `"  Read  "`. The task says to reject blank titles, it does not say to change titles.

4. No re-sorting after import. `importMerging` keeps replaced items where they were and adds new items at the end. So after an import the plan is not always sorted by title. This follows the rule "replace at current positions". Sorting happens only when a plan is created or decoded.

5. Import replaces the whole item. A replaced item takes everything from the incoming version, including `isCompleted`. So a completed task can become not completed if the import says so. The task says "replace", so I replace fully.

6. Items are matched by ID, not by content. This is what the task asks for, and it is right when both lists come from the same source, like a phone and a laptop. If two unrelated lists use the same ID by chance, the incoming item will overwrite the other one. This is outside the scope of the homework.

7. API compatibility. The hidden tests call the public methods by their exact names. I did not rename or change any public signature. I checked the public declarations against the template with `diff`, and the only additions are the two `init(from:)` methods.

## `swift test` verification

All runs were done on 2026-09-27 with Swift 6.3.2 on macOS, using the command `swift test` in the project root. Sometimes I used `--filter` to run only some tests, because while other methods still had `fatalError`, one call to them would crash the whole test run.

1. Template, before any change. The public tests crashed at `Implement StudyItem validation`. This was expected.
2. After step 1. `swift test --filter StudyPlannerStudentTests`: 4 tests, 0 failures. The two public validation tests also passed. The third public test was not run yet, because the plan methods were still empty.
3. After step 2. 9 tests (7 of mine and 2 public), 0 failures.
4. After step 3 and step 4. 13 tests, 0 failures.
5. After step 5. First full `swift test` without a filter: 21 tests (3 public and 18 of mine), 0 failures. Before this run the compiler error about `isCompleted` had to be fixed.
6. After step 6. 26 tests, 0 failures. After rewriting `importMerging`: still 26 tests, 0 failures, with no test changes.
7. After step 7. 28 tests, 0 failures. I also deleted the `.build` folder and ran `swift test` from a clean build: 28 tests, 0 failures, no warnings. After switching to a normal `import`, all my tests still compiled and passed. After adding the save and load test: 29 tests, 0 failures.
8. Final result: 29 tests (3 public and 26 of mine), 0 failures. The output is saved in `artifacts/swift-test.log`.




Building for debugging...
[0/2] Write swift-version--58304C5D6DBC2206.txt
Build complete! (0.11s)
Test Suite 'All tests' started at 2026-09-27 22:02:32.188.
Test Suite 'StudyPlannerPackageTests.xctest' started at 2026-09-27 22:02:32.192.
Test Suite 'StudyPlannerPublicTests' started at 2026-09-27 22:02:32.192.
Test Case '-[StudyPlannerTests.StudyPlannerPublicTests testBlankTitleIsRejected]' started.
Test Case '-[StudyPlannerTests.StudyPlannerPublicTests testBlankTitleIsRejected]' passed (0.001 seconds).
Test Case '-[StudyPlannerTests.StudyPlannerPublicTests testIncompleteMinutesAndCompletion]' started.
Test Case '-[StudyPlannerTests.StudyPlannerPublicTests testIncompleteMinutesAndCompletion]' passed (0.000 seconds).
Test Case '-[StudyPlannerTests.StudyPlannerPublicTests testValidItemStoresValues]' started.
Test Case '-[StudyPlannerTests.StudyPlannerPublicTests testValidItemStoresValues]' passed (0.000 seconds).
Test Suite 'StudyPlannerPublicTests' passed at 2026-09-27 22:02:32.193.
	 Executed 3 tests, with 0 failures (0 unexpected) in 0.001 (0.001) seconds
Test Suite 'StudyPlannerStudentTests' started at 2026-09-27 22:02:32.193.
Test Case '-[StudyPlannerTests.StudyPlannerStudentTests testBlankTitleIsReportedBeforeBadMinutes]' started.
Test Case '-[StudyPlannerTests.StudyPlannerStudentTests testBlankTitleIsReportedBeforeBadMinutes]' passed (0.000 seconds).
Test Case '-[StudyPlannerTests.StudyPlannerStudentTests testDecodingItemWithBlankTitleThrowsBlankTitle]' started.
Test Case '-[StudyPlannerTests.StudyPlannerStudentTests testDecodingItemWithBlankTitleThrowsBlankTitle]' passed (0.000 seconds).
Test Case '-[StudyPlannerTests.StudyPlannerStudentTests testDecodingItemWithoutIsCompletedDefaultsToFalse]' started.
Test Case '-[StudyPlannerTests.StudyPlannerStudentTests testDecodingItemWithoutIsCompletedDefaultsToFalse]' passed (0.000 seconds).
Test Case '-[StudyPlannerTests.StudyPlannerStudentTests testDecodingItemWithUnknownCategoryFails]' started.
Test Case '-[StudyPlannerTests.StudyPlannerStudentTests testDecodingItemWithUnknownCategoryFails]' passed (0.000 seconds).
Test Case '-[StudyPlannerTests.StudyPlannerStudentTests testDecodingItemWithZeroMinutesThrowsNonPositiveMinutes]' started.
Test Case '-[StudyPlannerTests.StudyPlannerStudentTests testDecodingItemWithZeroMinutesThrowsNonPositiveMinutes]' passed (0.000 seconds).
Test Case '-[StudyPlannerTests.StudyPlannerStudentTests testDecodingKeyedPlanRejectsInvalidItem]' started.
Test Case '-[StudyPlannerTests.StudyPlannerStudentTests testDecodingKeyedPlanRejectsInvalidItem]' passed (0.000 seconds).
Test Case '-[StudyPlannerTests.StudyPlannerStudentTests testDecodingKeyedPlanValidatesAndSortsItems]' started.
Test Case '-[StudyPlannerTests.StudyPlannerStudentTests testDecodingKeyedPlanValidatesAndSortsItems]' passed (0.000 seconds).
Test Case '-[StudyPlannerTests.StudyPlannerStudentTests testDecodingTopLevelArrayFixture]' started.
Test Case '-[StudyPlannerTests.StudyPlannerStudentTests testDecodingTopLevelArrayFixture]' passed (0.001 seconds).
Test Case '-[StudyPlannerTests.StudyPlannerStudentTests testDecodingTopLevelArrayRejectsDuplicateIDs]' started.
Test Case '-[StudyPlannerTests.StudyPlannerStudentTests testDecodingTopLevelArrayRejectsDuplicateIDs]' passed (0.000 seconds).
Test Case '-[StudyPlannerTests.StudyPlannerStudentTests testDecodingValidItemReadsAllFields]' started.
Test Case '-[StudyPlannerTests.StudyPlannerStudentTests testDecodingValidItemReadsAllFields]' passed (0.000 seconds).
Test Case '-[StudyPlannerTests.StudyPlannerStudentTests testFirstRepeatedIDIsReported]' started.
Test Case '-[StudyPlannerTests.StudyPlannerStudentTests testFirstRepeatedIDIsReported]' passed (0.000 seconds).
Test Case '-[StudyPlannerTests.StudyPlannerStudentTests testImportAppendsNewIDsInAscendingIDOrder]' started.
Test Case '-[StudyPlannerTests.StudyPlannerStudentTests testImportAppendsNewIDsInAscendingIDOrder]' passed (0.000 seconds).
Test Case '-[StudyPlannerTests.StudyPlannerStudentTests testImportMixesReplacementsAndNewItems]' started.
Test Case '-[StudyPlannerTests.StudyPlannerStudentTests testImportMixesReplacementsAndNewItems]' passed (0.000 seconds).
Test Case '-[StudyPlannerTests.StudyPlannerStudentTests testImportOfEmptyListChangesNothing]' started.
Test Case '-[StudyPlannerTests.StudyPlannerStudentTests testImportOfEmptyListChangesNothing]' passed (0.000 seconds).
Test Case '-[StudyPlannerTests.StudyPlannerStudentTests testImportReplacesExistingIDAtItsCurrentPosition]' started.
Test Case '-[StudyPlannerTests.StudyPlannerStudentTests testImportReplacesExistingIDAtItsCurrentPosition]' passed (0.000 seconds).
Test Case '-[StudyPlannerTests.StudyPlannerStudentTests testImportWithDuplicateIncomingIDsThrowsAndKeepsPlan]' started.
Test Case '-[StudyPlannerTests.StudyPlannerStudentTests testImportWithDuplicateIncomingIDsThrowsAndKeepsPlan]' passed (0.000 seconds).
Test Case '-[StudyPlannerTests.StudyPlannerStudentTests testIncompleteMinutesSkipsCompletedItems]' started.
Test Case '-[StudyPlannerTests.StudyPlannerStudentTests testIncompleteMinutesSkipsCompletedItems]' passed (0.000 seconds).
Test Case '-[StudyPlannerTests.StudyPlannerStudentTests testItemsInCategoryReturnsOnlyThatCategoryInPlanOrder]' started.
Test Case '-[StudyPlannerTests.StudyPlannerStudentTests testItemsInCategoryReturnsOnlyThatCategoryInPlanOrder]' passed (0.000 seconds).
Test Case '-[StudyPlannerTests.StudyPlannerStudentTests testItemsInCategoryWithNoMatchesIsEmpty]' started.
Test Case '-[StudyPlannerTests.StudyPlannerStudentTests testItemsInCategoryWithNoMatchesIsEmpty]' passed (0.000 seconds).
Test Case '-[StudyPlannerTests.StudyPlannerStudentTests testMarkCompletedTwiceIsIdempotent]' started.
Test Case '-[StudyPlannerTests.StudyPlannerStudentTests testMarkCompletedTwiceIsIdempotent]' passed (0.000 seconds).
Test Case '-[StudyPlannerTests.StudyPlannerStudentTests testMarkCompletedWithUnknownIDThrowsAndKeepsPlan]' started.
Test Case '-[StudyPlannerTests.StudyPlannerStudentTests testMarkCompletedWithUnknownIDThrowsAndKeepsPlan]' passed (0.000 seconds).
Test Case '-[StudyPlannerTests.StudyPlannerStudentTests testSameTitlesAreOrderedByID]' started.
Test Case '-[StudyPlannerTests.StudyPlannerStudentTests testSameTitlesAreOrderedByID]' passed (0.000 seconds).
Test Case '-[StudyPlannerTests.StudyPlannerStudentTests testSavedPlanLoadsBackWithoutLosingData]' started.
Test Case '-[StudyPlannerTests.StudyPlannerStudentTests testSavedPlanLoadsBackWithoutLosingData]' passed (0.000 seconds).
Test Case '-[StudyPlannerTests.StudyPlannerStudentTests testValidItemKeepsOriginalTitleAndAllFields]' started.
Test Case '-[StudyPlannerTests.StudyPlannerStudentTests testValidItemKeepsOriginalTitleAndAllFields]' passed (0.000 seconds).
Test Case '-[StudyPlannerTests.StudyPlannerStudentTests testWhitespaceOnlyTitleThrowsBlankTitle]' started.
Test Case '-[StudyPlannerTests.StudyPlannerStudentTests testWhitespaceOnlyTitleThrowsBlankTitle]' passed (0.000 seconds).
Test Case '-[StudyPlannerTests.StudyPlannerStudentTests testZeroAndNegativeMinutesThrowNonPositiveMinutes]' started.
Test Case '-[StudyPlannerTests.StudyPlannerStudentTests testZeroAndNegativeMinutesThrowNonPositiveMinutes]' passed (0.000 seconds).
Test Suite 'StudyPlannerStudentTests' passed at 2026-09-27 22:02:32.197.
	 Executed 26 tests, with 0 failures (0 unexpected) in 0.003 (0.004) seconds
Test Suite 'StudyPlannerPackageTests.xctest' passed at 2026-09-27 22:02:32.197.
	 Executed 29 tests, with 0 failures (0 unexpected) in 0.004 (0.005) seconds
Test Suite 'All tests' passed at 2026-09-27 22:02:32.197.
	 Executed 29 tests, with 0 failures (0 unexpected) in 0.004 (0.010) seconds
◇ Test run started.
↳ Testing Library Version: 1902
↳ Target Platform: arm64e-apple-macos14.0
✔ Test run with 0 tests in 0 suites passed after 0.001 seconds.







Test coverage. My 26 tests are unit tests. They check each rule from the task through the public API: validation, JSON decoding and saving, duplicates, sorting, queries, completion and import. Most of them work only in memory. One test reads the real fixture file from disk.

The logic in this library is not complex. It has no database, no network and no user interface, and the only outside boundary is JSON, which is already covered by tests. So separate integration tests, UI tests or performance tests are not needed here.

To see the library working outside the tests, there is a separate demo target in the `Demo/` folder. It is its own package and uses the library from the parent folder. It creates items, builds a plan, runs every query, decodes JSON and runs an import, and prints each result or the error that was thrown. To run it:

```sh
cd Demo
swift run
```

I ran it and the output matched the expected behavior for every task.


olesiamykhailyshyn@11800-L-P-0320 SE250 Apple Platform Development % cd "/Users/olesiamykhailyshyn/Documents/KSE/SE250 Apple Platform Development/apd-hw-1/Demo"
swift run

[1/1] Planning build
Building for debugging...
[2/2] Emitting module StudyPlannerDemo
Build of product 'StudyPlannerDemo' complete! (0.40s)

=== Task 1: validation ===
  OK     valid item
  ERROR  blank title -> blankTitle
  ERROR  zero minutes -> nonPositiveEstimatedMinutes
  ERROR  blank title and zero minutes -> blankTitle

=== Task 3: duplicates and sorting ===
  [ ] j1: Build milestone, 90 min, project
  [ ] p1: Practice drills, 30 min, practice
  [ ] r0: Read chapter, 20 min, reading
  [ ] r1: Read chapter, 45 min, reading
  ERROR  plan with duplicate id -> duplicateID("a")

=== Task 4: queries and completion ===
  reading: ["r0", "r1"], incomplete minutes: 185
  OK     complete r1
  OK     complete r1 again
  ERROR  complete unknown id -> unknownID("banana")
  incomplete minutes: 140
  [ ] j1: Build milestone, 90 min, project
  [ ] p1: Practice drills, 30 min, practice
  [ ] r0: Read chapter, 20 min, reading
  [x] r1: Read chapter, 45 min, reading

=== Task 2: decoding JSON ===
  [ ] a: First, 10 min, reading
  [ ] b: Second, 20 min, practice
  [ ] k: Keyed, 15 min, project
  ERROR  decode blank title -> blankTitle
  ERROR  decode unknown category -> DecodingError.dataCorrupted: Data was corrupted. Path: category. Debug description: Cannot initialize StudyCategory from invalid String value banana

=== Bonus: importMerging ===
  OK     replace j1, add zz and aa
  [ ] j1: Build milestone v2, 120 min, project
  [ ] p1: Practice drills, 30 min, practice
  [ ] r0: Read chapter, 20 min, reading
  [x] r1: Read chapter, 45 min, reading
  [ ] aa: Read article, 15 min, reading
  [ ] zz: Watch talk, 25 min, reading
  ERROR  import with duplicate incoming id -> duplicateID("dup")
  plan unchanged after failed import: true