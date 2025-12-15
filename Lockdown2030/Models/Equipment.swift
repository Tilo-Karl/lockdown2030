//
//  Equipment.swift
//  Lockdown2030
//
//  Created by Tilo Delau on 2025-12-15.
//


import Foundation

/// Mirrors your backend equipment shape (slot + layer).
/// Keep it small; you can extend later.
struct Equipment: Equatable {
    struct Body: Equatable {
        var under: String?   // itemId
        var outer: String?   // itemId
    }

    struct Weapon: Equatable {
        var main: String?    // itemId
        var off: String?     // itemId (future)
    }

    var body: Body?
    var weapon: Weapon?
}