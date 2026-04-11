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

        vm.currentWord = "ANT"
        vm.submitWord(selectedLetters: [])

        XCTAssertEqual(vm.foundWords, ["ant"])
        XCTAssertEqual(vm.score, 1)
        XCTAssertNil(vm.userMessage)
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
        vm.currentWord = "AN"
        vm.submitWord(selectedLetters: [])

        XCTAssertEqual(vm.foundWords, ["an"])
        XCTAssertEqual(vm.score, 0)
        XCTAssertNil(vm.userMessage)
    }
}
