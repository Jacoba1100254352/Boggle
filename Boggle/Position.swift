// =============================================================
// Position.swift
// =============================================================

import Foundation

/// A single tile coordinate on the 2‑D Boggle board.
struct Position: Hashable, Sendable {
    let row: Int
    let col: Int
}
