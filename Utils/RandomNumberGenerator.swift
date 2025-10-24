//
//  RandomNumberGenerator.swift
//  cards
//
//  Created by Darryl Mah on 9/27/25.
//

import Foundation

/// Deterministic random number generator for reproducible game states
struct SplitMix64: RandomNumberGenerator {
    private var state: UInt64
    
    init(seed: UInt64) { 
        self.state = seed &+ 0x9E3779B97F4A7C15 
    }
    
    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}