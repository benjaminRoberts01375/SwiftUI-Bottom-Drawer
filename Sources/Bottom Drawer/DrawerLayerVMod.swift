// Created on 10/1/23 by Ben Roberts
// Created for the Bottom Drawer library
//
// Swift 5.0
//

import SwiftUI

private struct DrawerLayer: ViewModifier {
    private let cornerRadius: CGFloat = 20
    
    fileprivate func body(content: Content) -> some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .foregroundStyle(.regularMaterial)
            .overlay {
                content
            }
            .clipped()
    }
}

public extension View {
    func drawerLayer() -> some View {
        modifier(DrawerLayer())
    }
}
