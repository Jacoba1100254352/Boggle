import Foundation

/// Builds Boggle boards from letter-balanced dice instead of choosing every
/// tile from a uniform alphabet. This produces boards with a useful mix of
/// vowels and consonants while preserving a fresh shuffle every round.
enum BoardGenerator {
    private static let classicDice = [
        "AAEEGN", "ABBJOO", "ACHOPS", "AFFKPS",
        "AOOTTW", "CIMOTU", "DEILRX", "DELRVY",
        "DISTTY", "EEGHNW", "EEINSU", "EHRTVW",
        "EIOSST", "ELRTTY", "HIMNQU", "HLNNRZ"
    ]

    private static let expandedDice = [
        "AAAFRS", "AAEEEE", "AAFIRS", "ADENNN", "AEEEEM",
        "AEEGMU", "AEGMNN", "AFIRSY", "BJKQXZ", "CCENST",
        "CEIILT", "CEILPT", "CEIPST", "DDHNOT", "DHHLOR",
        "DHHNOW", "DHLNOR", "EIIITT", "EMOTTT", "ENSSSU",
        "FIPRSY", "GORRVW", "HIPRRY", "NOOTUW", "OOOTTU"
    ]

    static func generate(for boardSize: BoardSize) -> [[String]] {
        var generator = SystemRandomNumberGenerator()
        return generate(for: boardSize, using: &generator)
    }

    static func generate<R: RandomNumberGenerator>(
        for boardSize: BoardSize,
        using generator: inout R
    ) -> [[String]] {
        let dimension = boardSize.dimension
        var dice = boardSize == .four ? classicDice : expandedDice
        dice.shuffle(using: &generator)

        let tiles = dice.map { die in
            let face = die.randomElement(using: &generator) ?? "A"
            return tileText(for: face)
        }

        return stride(from: 0, to: tiles.count, by: dimension).map { start in
            Array(tiles[start..<min(start + dimension, tiles.count)])
        }
    }

    static func tileText(for face: Character) -> String {
        face == "Q" ? "Qu" : String(face)
    }
}
