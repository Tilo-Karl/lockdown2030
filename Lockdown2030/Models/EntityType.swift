//
//  EntityType.swift
//  Lockdown2030
//
//  Created by Tilo Delau on 2025-12-15.
//


import Foundation

enum EntityType: String, Codable {
    case human  = "HUMAN"
    case zombie = "ZOMBIE"
    case item   = "ITEM"
}