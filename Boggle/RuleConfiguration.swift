// =============================================================
// RuleConfiguration.swift
// =============================================================

import Foundation

/// Captures the configurable rules for a Boggle round.
struct RuleConfiguration: Codable, Equatable {
    /// Minimum word length required to score points.
    var minimumWordLength: Int = 3
    /// Whether previously played words should be rejected.
    var enforceUniqueWords: Bool = true
    /// Length of a round in seconds.
    var roundDuration: Int = 180

    /// Ensures stored values remain inside sensible limits.
    func clamped() -> RuleConfiguration {
        var copy = self
        copy.minimumWordLength = max(2, min(8, minimumWordLength))
        copy.roundDuration = max(60, min(600, roundDuration))
        return copy
    }
}
