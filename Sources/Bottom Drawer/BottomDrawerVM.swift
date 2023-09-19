// Created on 9/15/23 by Ben Roberts
// Created for the Bottom Drawer library
//
// Swift 5.0
//

import SwiftUI

final class BottomDrawerVM: ObservableObject {
    private let verticalDetents: Set<VerticalDetents>
    private let horizontalDetents: Set<HorizontalDetents>
    internal var availableHeights: [CGFloat]
    internal var availableWidths: [CGFloat]
    private var minDetentDelta: CGFloat = 30
    
    @Published var height: CGFloat {
        didSet {
            if height <= 0 {
                height = 50
            }
        }
    }
    @Published var xPos: CGFloat = 0
    
    internal let shortCardSize: CGFloat = 300
    internal let requiredFreeWidth: CGFloat = 400
    @Published internal var isShortCard: Bool = false
    
    internal var viewHeight: CGFloat = 0
    
    init(verticalDetents: Set<VerticalDetents>, horizontalDetents: Set<HorizontalDetents>) {
        self.verticalDetents = verticalDetents
        self.horizontalDetents = horizontalDetents
        self.availableHeights = []
        self.availableWidths = []
        self.height = 200
    }
    
    internal func calculateAvailableHeights(screenSize: CGSize) {
        if verticalDetents.isEmpty { return }
        for detent in verticalDetents {
            switch detent {
            case .large:
                availableHeights.append(screenSize.height)
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
        
        filterDimensions(availables: &availableHeights)
    }
    
    internal func calculateAvailableWidths(screenSize: CGSize) {
        
    }
    
    private func filterDimensions(availables: inout [CGFloat]) {
        let first = availables.first ?? 0
        
        // Height range is crunched together shortcut
        if (availables.last ?? 0) - first <= minDetentDelta {
            availables = [first]
            return
        }
        
        // Remove any heights too close together
        for available in availables.dropLast() {
            guard let index = availables.firstIndex(of: available) else { continue }
            if availables[index + 1] - availables[index] < minDetentDelta {
                availables.remove(at: index + 1)
            }
        }
        
        // Maintain the max value at the expense of the second to largest value
        if availables[availables.count - 1] - availables[availables.count - 2] <= minDetentDelta {
            availables.remove(at: availables.count - 2)
        }
    }
    
    internal func calculateIsShortCard(size: CGSize) {
        isShortCard = size.width >= shortCardSize + requiredFreeWidth
        snapToPoint(velocity: 0)
    }
    
    internal func snapToPoint(velocity: CGFloat) {
        if availableHeights.isEmpty { return }
        let heightOffset = velocity / 6
        let distanceToPoint: CGFloat = availableHeights.map({ $0 - height + heightOffset }).reduce(.greatestFiniteMagnitude, { abs($0) < abs($1) ? $0 : $1 })
        
        withAnimation(.bouncy(duration: abs(1000 / velocity).clamped(to: 0.15...0.5))) {
            height += distanceToPoint - heightOffset
        }
    }
}
