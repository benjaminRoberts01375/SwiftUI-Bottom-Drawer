// Created on 9/15/23 by Ben Roberts
// Created for the Bottom Drawer library
//
// Swift 5.0
//

import SwiftUI

final class BottomDrawerVM: ObservableObject {
    /// Requested snap points for the height of the drawer.
    private let verticalDetents: Set<VerticalDetents>
    /// Requested snap points for dragging the drawer horizontally.
    private let horizontalDetents: Set<HorizontalDetents>
    /// Actual snap points for the height of the drawer.
    internal var availableHeights: [CGFloat]
    /// Actual snap points for dragging the drawer horizontally.
    internal var availableWidths: [CGFloat]
    /// Min allowed distance between snap points.
    private let minDetentDelta: CGFloat = 30
    
    /// Height of the drawer.
    @Published var height: CGFloat {
        didSet(oldHeight) {
            if !height.isNormal || height <= 0 {
                height = oldHeight
            }
        }
    }
    /// x position of the drawer.
    @Published var xPos: CGFloat = 0
    
    /// Width for when the drawer is short.
    internal let shortDrawerSize: CGFloat = 300
    /// Min allowed space available on screen next to the short drawer.
    private let requiredFreeWidth: CGFloat = 350
    /// Tracker for if the drawer should be rendered a limited width.
    @Published internal var isShortDrawer: Bool = false
    
    /// Tracker for the height of the header potentially passed to the drawer.
    internal var headerHeight: CGFloat = 0
    /// Tracker for the height of the content passed to the drawer.
    internal var contentHeight: CGFloat = 0
    /// Tracks if the drawer is allowing the user to use the scroll view.
    @Published internal var scrollable: Bool = false
    /// Prevent any amount of scrolling on the drawer.
    let preventAnyScroll: Bool
    /// Min x drag distance before distance is considered.
    private let minDragDistance: CGFloat = 40
    
    /// Controller for the bottom drawer.
    /// - Parameters:
    ///   - verticalDetents: Requested snap points for the height of the drawer.
    ///   - horizontalDetents: Requested snap points for dragging the drawer horizontally.
    init(verticalDetents: Set<VerticalDetents>, horizontalDetents: Set<HorizontalDetents>, preventScrolling: Bool) {
        self.verticalDetents = verticalDetents
        self.horizontalDetents = horizontalDetents
        self.availableHeights = []
        self.availableWidths = []
        self.height = 200
        self.preventAnyScroll = preventScrolling
    }
    
    /// Determine the available heights of the bottom drawer based on the requested heights and screen size.
    /// - Parameter screenSize: Size of the screen.
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
                let height = screenSize.height * fraction
                if height <= 0 { continue }
                availableHeights.append(height)
            case .exactly(let height):
                if height <= 0 { continue }
                availableHeights.append(height)
            case .header:
                availableHeights.append(headerHeight + 35)
            case .content:
                availableHeights.append(contentHeight + headerHeight + 45)
            }
        }
        
        // Check to ensure heights are within screen limits
        availableHeights = availableHeights.filter { $0 <= screenSize.height }.sorted()
        
        filterDimensions(availables: &availableHeights)
    }
    
    /// /// Determine the available x positions of the bottom drawer based on the requested widths and screen size.
    /// - Parameter screenSize: Size of the screen.
    private func calculateAvailableWidths(screenSize: CGSize) {
        if !isShortDrawer { return }
        availableWidths = []
        for detent in horizontalDetents {
            switch detent {
            case .left:
                availableWidths.append(0)
            case .right:
                availableWidths.append(screenSize.width - shortDrawerSize)
            case .center:
                availableWidths.append((screenSize.width - shortDrawerSize) / 2)
            }
            
            availableWidths = availableWidths.sorted()
            filterDimensions(availables: &availableWidths)
        }
    }
    
    /// Filter snap points based on proximity,
    /// - Parameter availables: Calculated snap points for x or y.
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
    
    /// Determine if the drawer is supposed to be rendered short due to screen dimensions.
    /// - Parameter size: Size of the screen
    private func calculateIsShortDrawer(size: CGSize) {
        isShortDrawer = size.width >= shortDrawerSize + requiredFreeWidth
        snapToPoint(velocity: .zero)
    }
    
    /// Determine the distance to the nearst snap point for the drawer
    /// - Parameters:
    ///   - snapPoints: Snap points to calculate from
    ///   - currentPosition: Current position of the bottom drawer
    ///   - offset: Any offsetting due to external factors like velocity. This can be used for passing snap points when the user flicks quickly.
    /// - Returns: Distance to the nearest snap point.
    private func calculateSnap(snapPoints: [CGFloat], currentPosition: CGFloat, offset: CGFloat = 0) -> CGFloat {
        let distanceToPoint: CGFloat = snapPoints.map({ $0 - currentPosition + offset }).reduce(.greatestFiniteMagnitude, { abs($0) < abs($1) ? $0 : $1 })
        return distanceToPoint - offset
    }
    
    /// Snap both the x and height based on the drawer's position and velocity.
    /// - Parameter velocity: Current velocity of the bottom drawer.
    internal func snapToPoint(velocity: CGSize = .zero) {
        var animation: (CGFloat) -> Animation { { velocity in
            return .bouncy(duration: abs(1000 / velocity).clamped(to: 0.2...0.5))
        }}
        
        if !availableHeights.isEmpty {
            withAnimation(velocity == .zero ? .linear : animation(velocity.height)) {
                height += calculateSnap(snapPoints: availableHeights, currentPosition: height, offset: velocity.height / 6)
            }
        }
        if !availableWidths.isEmpty {
            withAnimation(velocity == .zero ? .linear : animation(velocity.width)) {
                xPos += calculateSnap(snapPoints: availableWidths, currentPosition: xPos, offset: -velocity.width / 10)
            }
        }
    }
    
    /// A convienence function for completely repositioning the drawer based on a new screen size.
    /// - Parameters:
    ///   - size: Size of the screen
    ///   - safeAreas: Safe areas of the screen
    internal func recalculateAll(size: CGSize, safeAreas: EdgeInsets) {
        calculateIsShortDrawer(size: size)
        let sizeCalculation: CGSize = CGSize(
            width: size.width,
            height: size.height + (isShortDrawer ? -abs(safeAreas.top - safeAreas.bottom) : safeAreas.bottom)
        )
        calculateAvailableHeights(screenSize: sizeCalculation)
        calculateAvailableWidths(screenSize: sizeCalculation)
        snapToPoint()
        calculateScrollable()
    }
    
    /// Calculate the new height of the drawer during movement, and dampens accordingly.
    /// - Parameters:
    ///   - heightDelta: Change in height.
    ///   - dampening: Function for dampening the drawer as it moves.
    func calculateHeight(heightDelta: CGFloat, dampening: (CGFloat) -> CGFloat) {
        guard let maxSnapPoint = availableHeights.max(),
              let minSnapPoint = availableHeights.min()
        else { return }
        
        withAnimation(.easeInOut(duration: 0.25)) { // Handle any skips in frames
            if height > maxSnapPoint { // Above max height
                let distanceAbove = height - maxSnapPoint
                height += heightDelta * (1 / dampening(maxSnapPoint - height + 1))
            }
            else if height < minSnapPoint { // Below max height
                let distanceBelow = minSnapPoint - height
                height -= heightDelta * (1 / dampening(minSnapPoint - height + 1))
            }
            else { // Normal scrolling
                height -= heightDelta
            }
        }
    }
    
    /// Calculate the new x position during a drag gesture, and snap and dampen accordingly.
    /// - Parameters:
    ///   - dragValue: Value generated by a drag gesture.
    ///   - currentDrawerDrag: Distance the drawer has traveled during the gesture.
    ///   - dampening: Function for dampening the drawer as it moves.
    func calculateX(dragValue: DragGesture.Value, currentDrawerDrag: CGSize, dampening: (CGFloat) -> CGFloat) {
        if !isShortDrawer { return }
        let dragAmount = dragValue.location.x + shortDrawerSize / 2
        guard let nearestSnapPointToGesture = availableWidths.min(by: { abs($0 - dragValue.location.x + shortDrawerSize / 2) < abs($1 - dragValue.location.x + shortDrawerSize / 2) })
        else { return }
        
        if abs(dragValue.translation.width) < minDragDistance { return } // Min horizontal drag
        let xFrameDelta = dragValue.translation.width - currentDrawerDrag.width
        
        withAnimation(.easeInOut(duration: 0.25)) {
            xPos = nearestSnapPointToGesture - dampening(nearestSnapPointToGesture + shortDrawerSize / 2 - dragValue.location.x)
        }
    }
    
    /// Determine if the scroll view should be scrollable.
    func calculateScrollable() {
        if preventAnyScroll {
            scrollable = false
            return
        }
        if height >= contentHeight {
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
