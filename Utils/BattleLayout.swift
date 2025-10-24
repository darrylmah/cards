//
//  BattleLayout.swift
//  cards
//
//  Created by Darryl Mah on 09/27/25.
//

import SwiftUI

struct BattleLayout {
    static func computeCardSize(containerWidth: CGFloat) -> CGSize {
        // 4 cards per row (2 rows of 4) so each board fits without scrolling
        let columns: CGFloat = 4
        let spacing: CGFloat = 8
        let horizontalPadding: CGFloat = 16 * 2 // match .padding() in boards
        let totalSpacing = (columns - 1) * spacing
        let available = max(containerWidth - horizontalPadding - totalSpacing, 120)
        let w = floor(available / columns)
        return CGSize(width: w, height: w * 1.35)
    }
}
