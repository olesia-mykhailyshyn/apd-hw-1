# AI learning log

This is a curated summary of how I used an AI assistant (Claude Code) while doing this homework. Swift was new for me, so most of the conversation was me asking questions to understand the language, the task and the code before and after each change.

The questions below are written in my own words. It is not a copy of the chat and it has no private prompts or session data. Each item says what I asked, what the AI explained, and what I decided.

## 1. Understanding the assignment

- I asked what is in the template repository and what the point of the homework is. The AI listed the files and explained that the public API is already declared and every method body is a `fatalError` that I have to replace.
- I asked for Ukrainian translations of `README.md`, `TASKS_AND_GRADES.md`, `PLAN.md` and `AGENT_WORKLOG.md`, so I could read the requirements carefully.
- I asked how the hidden grader works. The AI explained that staff clone the repository at my commit, add their own tests and run `swift test`. This is why the public API names must not change.
- I asked why my tests go into a new file instead of the existing test file. The answer was that the supplied tests must not be changed, and the grader may replace that file.

## 2. Learning Swift syntax

- I asked what `: String, Codable, CaseIterable` after a type name means. The AI explained protocols (similar to interfaces in TypeScript), raw values of enums, and that Swift can generate `Codable` and `Equatable` code by itself.
- I said the syntax looks strange to me, so the AI gave me a Swift to TypeScript comparison table, which helped a lot.
- I asked why the code uses enums and not plain strings. I learned that an enum makes wrong values impossible to write, which also makes errors easy to compare in tests.
- I asked what `Package.swift` is and whether the AI changed it. It is the project description for Swift Package Manager, similar to `package.json`, and it was not changed.
- I asked what encoding and decoding mean and why we need them. I learned that encoding is object to JSON and decoding is JSON to object, and that data from outside must be checked when it is decoded.
- Later I asked about `mutating`, `guard let`, closures, `$0`, key paths like `\.id`, `??`, `Set` and `Dictionary`, every time I saw them in the code.

## 3. Task 1: validation

- I asked the AI to explain the task first: what exists, what to do, how and why. Only after that did I ask for the code.
- I asked for code that is easy to read, with checks split into separate lines instead of one long line.
- The first version used `guard !trimmedTitle.isEmpty`. I asked what it means and whether it can be written more simply. The AI showed four other ways (`if`, `allSatisfy`, a `String` extension and a one-liner). I chose the plain `if`, because it has no double negation.
- I tried storing the trimmed title. The AI pointed out that this breaks one of my tests and could fail hidden tests, because the task does not say to change titles. I decided to keep the original title.
- I asked whether the tests for task 1 are correct and whether writing tests is a requirement. The AI showed that tests are task 5 (2 points) and matched each test to a rule.

## 4. Task 2: JSON decoding

- I did not understand the first explanation, so I asked again in simpler words. The analogy with a main door (the validating init) and a back door (automatic JSON decoding with no checks) made it clear.
- The AI said that plan decoding needs `StudyPlan.init(items:)` from task 3. I asked to finish task 2 completely, so that init was implemented in the same step.
- I asked for a line-by-line explanation of `init(from decoder:)` and for other ways to write it. The AI showed a separate raw struct (DTO), an extension, and a strict `isCompleted` field. I kept the current version, because it is the most direct for five fields, and a strict field could fail hidden tests.

## 5. Tasks 3 and 4: duplicates, sorting, queries, completion

- The AI also pointed out that "first duplicate" can be read in two ways. We kept "first ID that repeats" and wrote it down as a risk.
- In task 4 the compiler showed `'isCompleted' setter is inaccessible`. The AI had explained `private(set)` wrongly before, and the compiler proved it wrong. The AI corrected itself: `private(set)` allows writing only inside `StudyItem`. The fix was a small internal method, `markAsCompleted()`, instead of changing the public declaration.
- I asked what `mutating` means and why the helper method is needed. I learned that struct methods must be marked `mutating` to change fields, and that the helper keeps "only the plan can tick an item" true.

## 6. Bonus: importMerging

- I asked for the meaning of the bonus, what it is for and which business situations need it. The AI gave examples: syncing a phone and a laptop, an updated course file, a broken file with duplicates.
- I asked how we know it is the same task just by ID, and whether it should be decided by content. The AI explained the idea of identity (like a student ID number), and that the task itself says to match by ID. We added the risk of two unrelated lists using the same ID to `PLAN.md`.
- I said the first solution should be done in a smarter way and asked for alternatives. The AI showed four options: dictionary with `map` and `filter`, a dictionary of indexes, rollback on error, and `OrderedDictionary`. I chose the dictionary with `map` and `filter`. I rejected rollback (not needed, because a struct copy is cheap) and `OrderedDictionary` (it needs an extra dependency). All bonus tests passed without changes.

## 7. Reviewing the whole code

- I went through the whole source file with the AI, part by part, and asked for syntax, purpose and possible improvements for each part.
- For sorting I asked to replace the `if/return` code with the tuple comparison `(title, id) < (title, id)`. I did not take `KeyPathComparator` (it compares text in a locale-aware way and could change the order) or `Comparable` on `StudyItem` (it would add to the public API).
- I asked whether all tasks have tests. The AI found two gaps (JSON without `isCompleted`, unknown category), and we added tests for them.
- I said tests must check business behavior and not code. The AI proved it by switching my test file from `@testable import` to a normal `import`: all tests still passed, so they only use the public API. It also pointed out that the tests did not change during two refactorings.
- When the editor showed a red line under `@testable import StudyPlanner`, I asked what the problem was. The AI explained that it was the editor's language server after the `.build` folder was deleted, not a real error, because `swift test` passed.

## 8. Demo program

- I asked for a program with a main entry point, so I could run the code and see how it works, not only through tests.
- The AI asked where to put it. I chose a separate package in `Demo/`, so the graded `Package.swift` stays unchanged.