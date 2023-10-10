// Created on 10/1/23 by Ben Roberts
// Created for the Bottom Drawer library
//
// Swift 5.0
//

import SwiftUI

private struct DrawerLayer: ViewModifier {
    internal let cornerRadii: RectangleCornerRadii
    /// Track dark/light mode
    @Environment(\.colorScheme) var colorScheme
    
    fileprivate func body(content: Content) -> some View {
        UnevenRoundedRectangle(cornerRadii: cornerRadii)
            .foregroundStyle(colorScheme == .light ? .regularMaterial : .thickMaterial)
            .overlay { content }
            .clipped()
    }
}

public extension View {
    func drawerLayer(cornerRadius: CGFloat = 20) -> some View {
        modifier(DrawerLayer(cornerRadii: RectangleCornerRadii(topLeading: cornerRadius, bottomLeading: cornerRadius, bottomTrailing: cornerRadius, topTrailing: cornerRadius)))
    }
    
    func drawerLayer(cornerRadii: RectangleCornerRadii) -> some View {
        modifier(DrawerLayer(cornerRadii: cornerRadii))
    }
}
