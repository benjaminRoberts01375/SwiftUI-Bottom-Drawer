// Created on 9/15/23 by Ben Roberts
// Created for the Bottom Drawer library
//
// Swift 5.0
//

import SwiftUI

final class BottomDrawerVM: ObservableObject {
    private let detents: Set<Detents>
    private var availableHeights: [CGFloat]
    internal var viewHeight: CGFloat = 0
    @Published var height: CGFloat {
        didSet {
            if height <= 0 {
                height = 50
            }
        }
    }
    
    init(detents: Set<Detents>) {
        self.detents = detents
        self.availableHeights = []
        self.height = 200
    }
    
    internal func calculateAvailableHeights(screenSize: CGSize) {
        if detents.isEmpty { return }
        for detent in detents {
            switch detent {
            case .large:
                availableHeights.append(screenSize.height * 0.9)
            case .medium:
                availableHeights.append(screenSize.height * 0.5)
            case .small:
                availableHeights.append(screenSize.height * 0.2)
            case .fraction(let fraction):
                availableHeights.append(screenSize.height * fraction)
            case .exactly(let height):
                availableHeights.append(height)
            case .view:
                availableHeights.append(viewHeight)
            }
        }
    }
    
    internal func snapToPoint(velocity: CGFloat) {
        if availableHeights.isEmpty { return }
        let heightOffset = velocity
        let distanceToPoint: CGFloat = availableHeights.map({ $0 - height + heightOffset }).reduce(.greatestFiniteMagnitude, { abs($0) < abs($1) ? $0 : $1 })
        
        withAnimation(.bouncy(duration: min(abs(1000 / velocity), 0.5))) {
            height += distanceToPoint - heightOffset
        }
    }
}
