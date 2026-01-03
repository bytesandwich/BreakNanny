//
//  CodingBlock.swift
//  BreakNanny
//
//  Created by John Phelan on 12/22/25.
//

import Foundation

struct AppActivity: Identifiable, Codable {
    var id: String { appName }
    let appName: String
    let activeMinutes: Int
}

struct CodingBlock: Identifiable, Codable {
    let id: UUID
    let intendedDescription: String
    var actualDescription: String
    let plannedCodingDuration: Int // in seconds
    let plannedBreakDuration: Int // in seconds
    var actualCodingDuration: Int // in seconds
    var actualBreakDuration: Int // in seconds
    var completedAt: Date? // when the block was completed

    // Activity tracking
    var appActivity: [AppActivity] = []  // Top apps sorted by minutes desc
    var totalActiveMinutes: Int = 0
    var totalMinutes: Int = 0

    init(
        id: UUID = UUID(),
        intendedDescription: String,
        actualDescription: String = "",
        plannedCodingDuration: Int,
        plannedBreakDuration: Int,
        actualCodingDuration: Int = 0,
        actualBreakDuration: Int = 0,
        completedAt: Date? = nil,
        appActivity: [AppActivity] = [],
        totalActiveMinutes: Int = 0,
        totalMinutes: Int = 0
    ) {
        self.id = id
        self.intendedDescription = intendedDescription
        self.actualDescription = actualDescription
        self.plannedCodingDuration = plannedCodingDuration
        self.plannedBreakDuration = plannedBreakDuration
        self.actualCodingDuration = actualCodingDuration
        self.actualBreakDuration = actualBreakDuration
        self.completedAt = completedAt
        self.appActivity = appActivity
        self.totalActiveMinutes = totalActiveMinutes
        self.totalMinutes = totalMinutes
    }
}
