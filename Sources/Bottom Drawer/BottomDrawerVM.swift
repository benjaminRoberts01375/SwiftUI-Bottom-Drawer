// Created on 9/15/23 by Ben Roberts
// Created for the Bottom Drawer library
//
// Swift 5.0
//

import SwiftUI

final class BottomDrawerVM: ObservableObject {
    private let detents: Set<Detents>
    private var availableHeights: [CGFloat]
    private var minDetentDelta: CGFloat = 30

    @Published var height: CGFloat {
        didSet {
            if height <= 0 {
                height = 50
            }
        }
    }

    internal var viewHeight: CGFloat = 0
    
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
                height = screenSize.height * fraction
                if height <= 0 { continue }
                availableHeights.append(height)
            case .exactly(let height):
                if height <= 0 { continue }
                availableHeights.append(height)
            case .view:
                availableHeights.append(viewHeight)
            }
        }
        
        // Check to ensure heights are within screen limits
        availableHeights = availableHeights.filter { $0 <= screenSize.height }.sorted()
        
        // Height range is crunched together shortcut
        if (availableHeights.last ?? 0) - (availableHeights.first ?? 0) <= 30 {
            availableHeights = [availableHeights.first ?? 0]
            return
        }
        
        // Remove any heights too close together
        for height in availableHeights.dropLast() {
            guard let index = availableHeights.firstIndex(of: height) else { continue }
            if availableHeights[index + 1] - availableHeights[index] < minDetentDelta {
                availableHeights.remove(at: index + 1)
            }
        }
        
        // Maintain the max value at the expense of the second to largest value
        if availableHeights[availableHeights.count - 1] - availableHeights[availableHeights.count - 2] <= minDetentDelta {
            availableHeights.remove(at: availableHeights.count - 2)
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
