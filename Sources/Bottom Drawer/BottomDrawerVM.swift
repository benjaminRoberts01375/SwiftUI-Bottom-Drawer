// Created on 9/15/23 by Ben Roberts
// Created for the Bottom Drawer library
//
// Swift 5.0
//

import SwiftUI

final class BottomDrawerVM: ObservableObject {
    private let detents: Set<Detents>
    private var availableHeights: [CGFloat]
    
    init(detents: Set<Detents>) {
        self.detents = detents
        self.availableHeights = []
    }
    
    internal func calculateAvailableHeights(screenSize: CGSize) {
        for detent in detents {
            switch detent {
            case .large:
                availableHeights.append(screenSize.height * 0.9)
            case .medium:
                availableHeights.append(screenSize.height * 0.5)
            case .small:
                availableHeights.append(150)
            case .fraction(let fraction):
                availableHeights.append(screenSize.height * fraction)
            case .exactly(let height):
                availableHeights.append(height)
            }
        }
    }
}
