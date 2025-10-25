//
//  BattleLayout.swift
//  cards
//
//  Created by Darryl Mah on 09/27/25.
//

import SwiftUI

struct BattleLayout {
    /// Number of card columns rendered in the battle grid.
    static let boardColumns: Int = 4

    /// Spacing between cards when laid out in a grid.
    static let gridSpacing: CGFloat = 8

    /// Outer padding applied around the battle boards.
    static let outerPadding: CGFloat = 16

    /// Minimum width we will allow a card to shrink to before clamping.
    static let minimumCardWidth: CGFloat = 120

    /// Visual style constants shared by the battle and builder UIs.
    static let cardCornerRadius: CGFloat = 10
    static let cardShadowRadius: CGFloat = 3
    static let cardHighlightLineWidth: CGFloat = 3

    /// Shake magnitude used for hit reactions.
    static let shakeAmount: CGFloat = 8

    /// Aspect ratio (height / width) used for cards throughout the app.
    static let cardAspectRatio: CGFloat = 1.35

    static func computeCardSize(containerWidth: CGFloat) -> CGSize {
        // 4 cards per row (2 rows of 4) so each board fits without scrolling
        let totalSpacing = CGFloat(boardColumns - 1) * gridSpacing
        let available = max(containerWidth - (outerPadding * 2) - totalSpacing, minimumCardWidth)
        let width = floor(available / CGFloat(boardColumns))
        return CGSize(width: width, height: width * cardAspectRatio)
    }
}
