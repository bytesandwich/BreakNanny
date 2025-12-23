//
//  CodingBlock.swift
//  BreakNanny
//
//  Created by John Phelan on 12/22/25.
//

import Foundation

struct CodingBlock: Identifiable, Codable {
    let id: UUID
    let intendedDescription: String
    var actualDescription: String
    let plannedCodingDuration: Int // in seconds
    let plannedBreakDuration: Int // in seconds
    var actualCodingDuration: Int // in seconds
    var actualBreakDuration: Int // in seconds
    var completedAt: Date? // when the block was completed

    init(
        id: UUID = UUID(),
        intendedDescription: String,
        actualDescription: String = "",
        plannedCodingDuration: Int,
        plannedBreakDuration: Int,
        actualCodingDuration: Int = 0,
        actualBreakDuration: Int = 0,
        completedAt: Date? = nil
    ) {
        self.id = id
        self.intendedDescription = intendedDescription
        self.actualDescription = actualDescription
        self.plannedCodingDuration = plannedCodingDuration
        self.plannedBreakDuration = plannedBreakDuration
        self.actualCodingDuration = actualCodingDuration
        self.actualBreakDuration = actualBreakDuration
        self.completedAt = completedAt
    }
}
