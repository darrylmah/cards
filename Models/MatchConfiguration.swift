//
//  MatchConfiguration.swift
//  cards
//
//  Created by Darryl Mah on 9/27/25.
//

import Foundation

struct MatchConfig: Decodable {
    let matchId: String
    let seed: UInt64
    let energyCap: Int?
}

enum RunMode: String, CaseIterable, Identifiable {
    case production, staging, offline
    
    var id: String { rawValue }
    
    var label: String {
        switch self {
        case .production: return "Production"
        case .staging:    return "Staging"
        case .offline:    return "Offline"
        }
    }
}