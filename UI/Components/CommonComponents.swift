//
//  CommonComponents.swift
//  cards
//
//  Created by Darryl Mah on 10/17/25.
//

import SwiftUI

struct Tag: View {
    let text: String
    init(_ t: String) { text = t }
    var body: some View {
        Text(text)
            .font(.system(size: 10, weight: .semibold))
            .padding(.horizontal, 6).padding(.vertical, 2)
            .background(.thinMaterial, in: Capsule())
    }
}
