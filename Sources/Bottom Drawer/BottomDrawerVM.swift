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
    private let minDetentDelta: CGFloat = 30
    
    @Published var height: CGFloat {
        didSet(oldHeight) {
            if !height.isNormal || height <= 0 {
                height = oldHeight
            }
        }
    }
    @Published var xPos: CGFloat = 0
    
    internal let shortCardSize: CGFloat = 300
    private let requiredFreeWidth: CGFloat = 350
    @Published internal var isShortCard: Bool = false
    
    internal var viewHeight: CGFloat = 0
    @Published internal var scrollable: Bool = false
    private let minDragDistance: CGFloat = 40
    
    init(verticalDetents: Set<VerticalDetents>, horizontalDetents: Set<HorizontalDetents>) {
        self.verticalDetents = verticalDetents
        self.horizontalDetents = horizontalDetents
        self.availableHeights = []
        self.availableWidths = []
        self.height = 200
    }
    
    private func calculateAvailableHeights(screenSize: CGSize) {
        if verticalDetents.isEmpty { return }
        availableHeights = []
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
    
    private func calculateAvailableWidths(screenSize: CGSize) {
        if !isShortCard { return }
        
        for detent in horizontalDetents {
            switch detent {
            case .left:
                availableWidths.append(0)
            case .right:
                availableWidths.append(screenSize.width - shortCardSize)
            case .center:
                availableWidths.append((screenSize.width - shortCardSize) / 2)
            }
            
            availableWidths = availableWidths.sorted()
            filterDimensions(availables: &availableWidths)
        }
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
    
    private func calculateIsShortCard(size: CGSize) {
        isShortCard = size.width >= shortCardSize + requiredFreeWidth
        snapToPoint(velocity: .zero)
    }
    
    private func calculateSnap(snapPoints: [CGFloat], currentPosition: CGFloat, offset: CGFloat = 0) -> CGFloat {
        let distanceToPoint: CGFloat = snapPoints.map({ $0 - currentPosition + offset }).reduce(.greatestFiniteMagnitude, { abs($0) < abs($1) ? $0 : $1 })
        return distanceToPoint - offset
    }
    
    internal func snapToPoint(velocity: CGSize = .zero) {
        var animation: (CGFloat) -> Animation { { velocity in
            return .bouncy(duration: abs(1000 / velocity).clamped(to: 0.2...0.5))
        }}
        
        if availableHeights.count > 0 {
            withAnimation(velocity == .zero ? .linear : animation(velocity.height)) {
                height += calculateSnap(snapPoints: availableHeights, currentPosition: height, offset: velocity.height / 6)
            }
        }
        if availableWidths.count > 0 {
            withAnimation(velocity == .zero ? .linear : animation(velocity.width)) {
                xPos += calculateSnap(snapPoints: availableWidths, currentPosition: xPos, offset: -velocity.width / 10)
            }
        }
    }
    
    internal func recalculateAll(size: CGSize, safeAreas: EdgeInsets) {
        let sizeCalculation: CGSize = CGSize(
            width: size.width,
            height: size.height + (isShortCard ? -safeAreas.bottom : safeAreas.bottom)
        )
        
        calculateIsShortCard(size: size)
        calculateAvailableHeights(screenSize: sizeCalculation)
        calculateAvailableWidths(screenSize: sizeCalculation)
        snapToPoint()
        calculateScrollable()
    }

    func calculateY(heightDelta: CGFloat, dampening: (CGFloat) -> CGFloat) {
        guard let maxSnapPoint = availableHeights.max(),
              let minSnapPoint = availableHeights.min()
        else { return }
        
        if height > maxSnapPoint { // Above max height
            let distanceAbove = height - maxSnapPoint
            height += heightDelta * (1 / dampening(maxSnapPoint - height + 1))
        }
        else if height < minSnapPoint { // Below max height
            let distanceBelow = minSnapPoint - height
            height -= heightDelta * (1 / dampening(minSnapPoint - height + 1))
        }
        else { // Normal scrolling
            withAnimation(.easeInOut(duration: 0.1)) { // Handle any skips in frames
                height -= heightDelta
            }
        }
    }
    
    func calculateX(dragValue: DragGesture.Value, currentDrawerDrag: CGSize, dampening: (CGFloat) -> CGFloat) {
        if !isShortCard { return }
        let dragAmount = dragValue.location.x + shortCardSize / 2
        guard let nearestSnapPointToGesture = availableWidths.min(by: { abs($0 - dragValue.location.x + shortCardSize / 2) < abs($1 - dragValue.location.x + shortCardSize / 2) })
        else { return }
        
        if abs(dragValue.translation.width) < minDragDistance { return } // Min horizontal drag
        let xFrameDelta = dragValue.translation.width - currentDrawerDrag.width
        
        withAnimation(.easeInOut(duration: 0.5)) {
            xPos = nearestSnapPointToGesture - dampening(nearestSnapPointToGesture + shortCardSize / 2 - dragValue.location.x)
        }
    }
    
    func calculateScrollable() {
        if height >= viewHeight {
            scrollable = false
            return
        }
        if height == availableHeights.last {
            scrollable = true
            return
        }
        scrollable = false
    }
}
