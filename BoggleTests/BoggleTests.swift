//
//  BoggleTests.swift
//  BoggleTests
//

import XCTest
@testable import Boggle

final class BoggleTests: XCTestCase {

    func testMinLengthRuleUsesConfiguredLength() {
        let rule = MinLengthRule(minLen: 4)
        let context = GameContext(grid: [], previousWords: [])

        let result = rule.validate(word: "cat", path: [], context: context)

        switch result {
        case .failure(let reason):
            XCTAssertEqual(reason, "Word must be at least 4 letters")
        default:
            XCTFail("Expected the rule to reject short words.")
        }
    }

    func testGameSettingsSummaryReflectsEnabledRules() {
        let settings = GameSettings(
            options: [.uniqueWords],
            minimumWordLength: 5,
            boardSize: .five,
            roundDuration: .sevenMinutes
        )

        XCTAssertEqual(
            settings.summaryText,
            "5x5 board / 7 min / No minimum length / Unique words only"
        )
    }

    func testBoardWordFinderReturnsPlayableWordsAndPaths() {
        let grid = makeGrid(["CONI", "ABIC", "FIXS", "DELT"])
        let words = BoardWordFinder.findWords(
            in: grid,
            dictionary: ["fix", "conic", "coin", "tone"],
            minimumLength: 3
        )

        XCTAssertEqual(Set(words.map(\.word)), Set(["fix", "conic", "coin"]))
        XCTAssertEqual(
            words.first(where: { $0.word == "fix" })?.path,
            [
                Position(row: 2, col: 0),
                Position(row: 2, col: 1),
                Position(row: 2, col: 2)
            ]
        )
    }

    @MainActor
    func testApplyingSettingsStartsConfiguredRound() {
        let vm = GameViewModel()
        let settings = GameSettings(
            options: .standard,
            minimumWordLength: 4,
            boardSize: .five,
            roundDuration: .fiveMinutes
        )

        vm.applySettings(settings)

        XCTAssertEqual(vm.currentSettings, settings)
        XCTAssertEqual(vm.grid.count, 5)
        XCTAssertEqual(vm.grid.first?.count, 5)
        XCTAssertEqual(vm.timeRemaining, 300)
    }

    @MainActor
    func testInjectedDictionaryAllowsValidWordScoring() {
        let vm = GameViewModel(dictionary: ["ant"])
        let settings = GameSettings(
            options: .standard,
            minimumWordLength: 3,
            boardSize: .four,
            roundDuration: .threeMinutes
        )

        vm.applySettings(settings)
        vm.grid = makeGrid(["ANTA", "BBBB", "CCCC", "DDDD"])

        vm.currentWord = "ANT"
        XCTAssertTrue(vm.submitWord(selectedLetters: []))

        XCTAssertEqual(vm.foundWords, ["ant"])
        XCTAssertEqual(vm.score, 1)
        XCTAssertNil(vm.userMessage)
    }

    func testDictionaryParserNormalizesCRLFEntries() {
        let dictionary = GameViewModel.parseDictionary(from: "fix\r\nconic\r\n")

        XCTAssertTrue(dictionary.contains("fix"))
        XCTAssertTrue(dictionary.contains("conic"))
        XCTAssertFalse(dictionary.contains("fix\r"))
    }

    @MainActor
    func testShortWordsScoreZeroWhenMinimumLengthRuleIsDisabled() {
        let vm = GameViewModel(dictionary: ["an"])
        let settings = GameSettings(
            options: [],
            minimumWordLength: 3,
            boardSize: .four,
            roundDuration: .threeMinutes
        )

        vm.applySettings(settings)
        vm.grid = makeGrid(["ANBC", "DEFG", "HIJK", "LMNO"])
        vm.currentWord = "AN"
        XCTAssertTrue(vm.submitWord(selectedLetters: []))

        XCTAssertEqual(vm.foundWords, ["an"])
        XCTAssertEqual(vm.score, 0)
        XCTAssertNil(vm.userMessage)
    }

    @MainActor
    func testTypedWordMustBePlayableOnTheBoard() {
        let vm = GameViewModel(dictionary: ["cat", "dog"])
        vm.applySettings(.classic)
        vm.grid = makeGrid(["CATA", "BBBB", "EEEE", "FFFF"])

        vm.currentWord = "DOG"

        XCTAssertFalse(vm.submitWord(selectedLetters: []))
        XCTAssertTrue(vm.foundWords.isEmpty)
        XCTAssertEqual(
            vm.userMessage?.message,
            "That word can’t be made from connected tiles on this board."
        )
    }

    @MainActor
    func testTracedSubmissionMustMatchItsConnectedPath() {
        let vm = GameViewModel(dictionary: ["cat"])
        vm.applySettings(.classic)
        vm.grid = makeGrid(["CATA", "BBBB", "EEEE", "FFFF"])
        vm.currentWord = "CAT"

        let disconnectedPath = [
            Position(row: 0, col: 0),
            Position(row: 0, col: 1),
            Position(row: 3, col: 3)
        ]

        XCTAssertFalse(vm.submitWord(selectedLetters: disconnectedPath))
        XCTAssertTrue(vm.foundWords.isEmpty)
    }

    func testQuTileConsumesTwoLettersInOneBoardPosition() {
        let grid = [
            ["Qu", "E", "E", "N"],
            ["A", "B", "C", "D"],
            ["F", "G", "H", "I"],
            ["J", "K", "L", "M"]
        ]

        let match = BoardWordFinder.findWords(
            in: grid,
            dictionary: ["queen"],
            minimumLength: 3
        ).first

        XCTAssertEqual(match?.word, "queen")
        XCTAssertEqual(match?.path.count, 4)
        XCTAssertEqual(BoardWordFinder.word(along: match?.path ?? [], in: grid), "queen")
    }

    func testBoardGeneratorBuildsBalancedBoardDimensionsAndQuTiles() {
        var generator = SeededRandomNumberGenerator(seed: 42)
        let classicBoard = BoardGenerator.generate(for: .four, using: &generator)
        let expandedBoard = BoardGenerator.generate(for: .five, using: &generator)

        XCTAssertEqual(classicBoard.count, 4)
        XCTAssertTrue(classicBoard.allSatisfy { $0.count == 4 })
        XCTAssertEqual(expandedBoard.count, 5)
        XCTAssertTrue(expandedBoard.allSatisfy { $0.count == 5 })
        XCTAssertTrue(
            (classicBoard + expandedBoard)
                .flatMap { $0 }
                .allSatisfy { $0 == "Qu" || $0.count == 1 }
        )
        XCTAssertEqual(BoardGenerator.tileText(for: "Q"), "Qu")
    }

    @MainActor
    func testTimerUsesElapsedWallClockTime() {
        let vm = GameViewModel(dictionary: ["cat"])
        let start = Date(timeIntervalSinceReferenceDate: 1_000)

        vm.startGame(now: start)
        vm.refreshTimer(at: start.addingTimeInterval(61.2))

        XCTAssertEqual(vm.timeRemaining, 119)

        vm.refreshTimer(at: start.addingTimeInterval(181))

        XCTAssertTrue(vm.isRoundOver)
        XCTAssertEqual(vm.timeRemaining, 0)
    }

    private func makeGrid(_ rows: [String]) -> [[String]] {
        rows.map { $0.map(String.init) }
    }
}

private struct SeededRandomNumberGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed
    }

    mutating func next() -> UInt64 {
        state = state &* 6_364_136_223_846_793_005 &+ 1
        return state
    }
}
