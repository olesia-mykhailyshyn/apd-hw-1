# Agent worklog

Tool used for all entries: Claude Code (an AI coding assistant) in VS Code. It had access to this repository and could run commands such as `swift test`.

How I used it: Swift was a new language for me. I did not give the whole homework to the AI in one request. I went task by task. For each task I first asked for an explanation of the requirement, then asked for the code, then read the code with the AI line by line, asked about the syntax, asked for other ways to write it, and decided what to keep or change. A curated summary of my questions and decisions is in [artifacts/ai-learning-log.md](artifacts/ai-learning-log.md).

No secrets, tokens or private session data are included here.

## Entry 1. Understanding the assignment and setting up the repository

### Tool/agent task

I gave the AI the link to the template repository and asked it to explain what is in the repository, translate `README.md` and `TASKS_AND_GRADES.md` into Ukrainian, and explain the point of the homework. Then I asked it to create my own public repository with the template content.

### Output reviewed

A list of all template files and what each one is for, a translation of the README and the grading table, and an explanation of each task. For the repository: the AI checked that the template is not a GitHub template repository, renamed the teacher's remote to `upstream` and created `olesia-mykhailyshyn/apd-hw-1` as a public repository with `gh repo create`.

### Accepted/rejected/revised decision

Accepted a separate repository instead of a fork, so it is not listed under the teacher's forks. I also asked follow-up questions: how the hidden grader works, whether other students can find my repository, and why my tests must go into a new file. From the answers I decided to keep my work local and push closer to the deadline, and to never edit the supplied test file.

### Verification command/result

`git remote -v` showed `origin` pointing to my repository and `upstream` pointing to the template. The repository was visible on GitHub.

### Artifact links

[artifacts/ai-learning-log.md](artifacts/ai-learning-log.md), section 1.

## Entry 2. Learning Swift syntax and the domain model

### Tool/agent task

Before writing any code I asked the AI to explain the whole `StudyPlanner.swift` file: what each type is, why the code uses enums, what `: String, Codable, CaseIterable` means, what `let`, `struct` and `public private(set) var` are, what `StudyItem` and `StudyCategory` mean in real life, what `Package.swift` is, and what encoding and decoding are.

### Output reviewed

Explanations with a to-do list example and a Swift to TypeScript comparison table. No code was changed in this entry.

### Accepted/rejected/revised decision

None rejected. When an explanation was not clear, I asked again in simpler words, for example about encoding and decoding and about what `StudyItem` means. I checked my understanding by comparing each Swift construct with what I know from TypeScript.

### Verification command/result

No command. This entry was only for learning.

### Artifact links

[artifacts/ai-learning-log.md](artifacts/ai-learning-log.md), section 2.

## Entry 3. Task 1: StudyItem validation

### Tool/agent task

I asked the AI to explain task 1 in detail (what exists, what to do, why), then to write the body of `StudyItem.init` in a readable way, with the checks on separate lines. I also asked it to check whether the tests for task 1 are correct.

### Output reviewed

The body of `StudyItem.init` in `Sources/StudyPlanner/StudyPlanner.swift` and a new file `Tests/StudyPlannerTests/StudyPlannerStudentTests.swift` with 4 tests.

### Accepted/rejected/revised decision

Revised. The first version used `guard !trimmedTitle.isEmpty else { throw }`. I asked what it means and whether it can be simpler. After seeing the other options (`if`, `allSatisfy`, a `String` extension, a one-liner), I chose a plain `if`, because it has no double negation.

I also tried storing the trimmed title myself. The AI showed that this broke one of the tests and did not match the task, which only says to reject blank titles. I went back and kept the original title.

I removed the comment from the code myself.

### Verification command/result

`swift test --filter "StudyPlannerStudentTests|testValidItemStoresValues|testBlankTitleIsRejected"`: 6 tests, 0 failures.

### Artifact links

[artifacts/ai-learning-log.md](artifacts/ai-learning-log.md), section 3.

## Entry 4. Task 2: JSON decoding (and StudyPlan.init)

### Tool/agent task

I asked the AI to explain task 2. I did not understand the first explanation, so I asked for a simpler one. Then I asked it to implement the whole task.

### Output reviewed

`StudyItem.init(from:)`, `StudyPlan.init(from:)`, `StudyPlan.decode(from:)`, and 9 tests. Because plan decoding calls `StudyPlan.init(items:)`, the duplicate check and sorting from task 3 were written in this step too.

### Accepted/rejected/revised decision

Accepted after a line-by-line review. I asked about `container`, `CodingKeys`, `decodeIfPresent`, `??` and `self.init`. I asked for other ways to write the decoder. The AI showed a DTO struct, an extension, and a strict `isCompleted` field. I kept the current version. It is the clearest for five fields, and a strict field could fail hidden tests that send JSON without `isCompleted`.

### Verification command/result

`swift test` with a filter (the task 4 methods were still `fatalError`): 13 tests, 0 failures.

### Artifact links

[artifacts/ai-learning-log.md](artifacts/ai-learning-log.md), section 4.

## Entry 5. Tasks 3 and 4: duplicates, sorting, queries, completion

### Tool/agent task

I asked whether task 3 was fully done, and then asked for an explanation of task 4 and its implementation.

### Output reviewed

Two new tests for task 3, the bodies of `items(in:)`, `incompleteMinutes()` and `markCompleted(id:)`, a helper `markAsCompleted()`, and 5 new tests.

### Accepted/rejected/revised decision

Revised. The AI said task 3 code was complete but two tests were missing, and that "first duplicate" has two possible meanings. We added the tests and recorded the meaning we chose as a risk in `PLAN.md`.

During task 4 the compiler showed `'isCompleted' setter is inaccessible`. Earlier the AI had told me that `private(set)` allows writing from the same file. The compiler showed this was wrong: it allows writing only inside the type. The AI corrected the explanation. I accepted an internal helper method inside `StudyItem` instead of changing the public declaration to `fileprivate(set)`, because the task says not to change the published API. I then asked what `mutating` means and why the helper is needed.

### Verification command/result

`swift test`, first full run without a filter: 21 tests (3 public and 18 of mine), 0 failures.

### Artifact links

[artifacts/ai-learning-log.md](artifacts/ai-learning-log.md), section 5.

## Entry 6. Bonus: importMerging

### Tool/agent task

I asked the AI to explain the bonus rules, the business situations behind them and how to implement it, and then to implement it.

### Output reviewed

`importMerging`, a shared private function `rejectDuplicateIDs` used by both `init(items:)` and `importMerging`, and 5 tests.

### Accepted/rejected/revised decision

Revised. I questioned the rule: why is an item the same just because of its ID, and should it not be decided by content? The AI explained identity versus content, and we added the risk of unrelated lists with the same ID to `PLAN.md`.

Then I said the first solution (a loop with index search) should be smarter and asked for alternatives. From four options I chose a dictionary with `map` and `filter`. I rejected rollback on error (not needed, because a struct copy is cheap) and `OrderedDictionary` (it needs an extra package dependency). All 5 bonus tests passed before and after the rewrite without changes.

### Verification command/result

`swift test`: 26 tests, 0 failures, both before and after the rewrite.

### Artifact links

[artifacts/ai-learning-log.md](artifacts/ai-learning-log.md), section 6.

## Entry 7. Review of the whole code and tests

### Tool/agent task

I went through the source file and the test file with the AI part by part. For each part I asked what it does, how the syntax works, and whether it can be improved. I also asked whether all tasks are tested, whether we need integration tests, and whether the tests check behavior and not implementation.

### Output reviewed

A tuple comparison for sorting, two new decoding tests, a save-and-load test, the student test file switched to a normal `import`, and comments removed from the test file.

### Accepted/rejected/revised decision

Revised. I chose the tuple comparison `(title, id) < (title, id)` for sorting. I rejected `KeyPathComparator`, because it compares text in a locale-aware way and could change the order, and `Comparable` on `StudyItem`, because it would add to the public API. For `incompleteMinutes()` I kept the simple loop instead of `reduce`.

I asked for tests that check business behavior and not code. The AI proved it by switching to a normal `import StudyPlanner`, so the tests can see only the public API, and all of them still passed. I removed the comments from the source file myself and asked the AI to remove them from the tests.

### Verification command/result

`rm -rf .build` then `swift test` from a clean build: 28 tests, 0 failures, no warnings. After adding the save-and-load test: `swift test`, 29 tests (3 public and 26 of mine), 0 failures. A check with `diff` against the template showed no changed public signatures and an unchanged public test file.

### Artifact links

[artifacts/swift-test.log](artifacts/swift-test.log), [artifacts/ai-learning-log.md](artifacts/ai-learning-log.md), section 7.

## Entry 8. Demo program

### Tool/agent task

I asked for a program with a main entry point that calls all the code, so I could run it and see how it works, not only through tests.

### Output reviewed

A separate package in `Demo/` (`Demo/Package.swift` and `Demo/Sources/StudyPlannerDemo/main.swift`) that prints the result of every feature.

### Accepted/rejected/revised decision

Revised. The AI asked where to put the demo. I chose a separate package, so the graded `Package.swift` stays unchanged. After the first version I asked to remove comments and emoji, make the code more compact and add one comment at the top. I checked that the output shows the bonus rules, including the plan staying unchanged after a failed import.

### Verification command/result

`cd Demo && swift run`: every section printed the expected result. `swift test` in the project root still gave 0 failures.

### Artifact links

[artifacts/demo-output.txt](artifacts/demo-output.txt)

## Entry 9. Documentation

### Tool/agent task

I asked the AI to write `PLAN.md` following my instructions: plain language, user stories that follow INVEST, acceptance criteria, implementation steps in the order we did them, the risks explained, and a note about unit tests, why integration tests are not needed, and the demo target. Then I asked for this worklog and the learning log, describing honestly how I used the AI.

### Output reviewed

`PLAN.md`, `AGENT_WORKLOG.md` and `artifacts/ai-learning-log.md`.

### Accepted/rejected/revised decision

Revised. I asked for a Ukrainian translation of `PLAN.md`, so I could check every statement, and then edited the file. One sentence said the tests were always written before the code. That was not accurate, because in each step the code and tests were written together, so it was corrected.

### Verification command/result

`swift test`: 29 tests, 0 failures. I checked that every file linked from these documents exists in the repository.

### Artifact links

[PLAN.md](PLAN.md), [artifacts/ai-learning-log.md](artifacts/ai-learning-log.md), section 9.
