// Created on 9/14/23 by Ben Roberts
// Created for the Bottom Drawer library
//
// Swift 5.0
//

import SwiftUI

@available(iOS 16.0, macOS 13.0, *)
public struct BottomDrawer: View {
    private let cornerRadius: CGFloat = 20
    private let shadowRadius: CGFloat = 5
    @StateObject private var controller: BottomDrawerVM
    @State var currentDrawerDrag: CGSize = .zero
    private let minDragDistance: CGFloat = 40
    
    var transparency: CGFloat {
        get {
            if controller.availableHeights.isEmpty { return 0 }
            let maxHeight = controller.availableHeights[controller.availableHeights.count - 1]
            let fadeAtPercent = 0.75
            let maxFade = 0.5
            return ((controller.height - maxHeight * fadeAtPercent) / (maxHeight * (1 - fadeAtPercent)) * maxFade).clamped(to: 0...maxFade)
        }
    }
    
    private func calculateY(heightDelta: CGFloat, dampening: (CGFloat) -> CGFloat) {
        guard let maxSnapPoint = controller.availableHeights.max(),
              let minSnapPoint = controller.availableHeights.min()
        else { return }
        
        if controller.height > maxSnapPoint { // Above max height
            let distanceAbove = controller.height - maxSnapPoint
            controller.height += heightDelta * (1 / dampening(maxSnapPoint - controller.height + 1))
        }
        else if controller.height < minSnapPoint { // Below max height
            let distanceBelow = minSnapPoint - controller.height
            controller.height -= heightDelta * (1 / dampening(minSnapPoint - controller.height + 1))
        }
        else { // Normal scrolling
            controller.height -= heightDelta
        }
    }
    
    private func calculateX(dragValue: DragGesture.Value, dampening: (CGFloat) -> CGFloat) {
        if !controller.isShortCard { return }
        let dragAmount = dragValue.location.x + controller.shortCardSize / 2
        guard let nearestSnapPointToGesture = controller.availableWidths.min(by: { abs($0 - dragValue.location.x + controller.shortCardSize / 2) < abs($1 - dragValue.location.x + controller.shortCardSize / 2) })
        else { return }
        
        if abs(dragValue.translation.width) < minDragDistance { return } // Min horizontal drag
        let xFrameDelta = dragValue.translation.width - currentDrawerDrag.width
        
        withAnimation(.easeInOut(duration: 0.5)) {
            controller.xPos = nearestSnapPointToGesture - dampening(nearestSnapPointToGesture + controller.shortCardSize / 2 - dragValue.location.x)
        }
    }
    
    var drawerDrag: some Gesture {
        DragGesture(coordinateSpace: .global)
            .onChanged { update in
                let dampening = { (distancePast: CGFloat) -> CGFloat in
                    let distance = pow(abs(distancePast), 1 / 1.5)
                    return distancePast < 0 ? -distance : distance
                }
                
                calculateY(heightDelta: update.translation.height - currentDrawerDrag.height, dampening: dampening)
                calculateX(dragValue: update, dampening: dampening)
                currentDrawerDrag = update.translation
            }
            .onEnded { update in
                controller.snapToPoint(velocity: update.velocity)
                currentDrawerDrag = .zero
            }
    }
    
    public init(verticalDetents: Set<VerticalDetents>, horizontalDetents: Set<HorizontalDetents>) {
        self._controller = StateObject(
            wrappedValue: BottomDrawerVM(
                verticalDetents: verticalDetents,
                horizontalDetents: horizontalDetents
            )
        )
    }
    
    public var body: some View {
        ZStack(alignment: .bottomTrailing) {
            if !controller.isShortCard {
                Color.black
                    .opacity(transparency)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }
            GeometryReader { geo in
                VStack {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .foregroundStyle(.regularMaterial)
                        .frame(
                            width: controller.isShortCard ? controller.shortCardSize : geo.size.width,
                            height: controller.height
                        )
                        .overlay {
                            ScrollView {
                                VStack {
                                    Capsule()
                                        .foregroundStyle(.gray)
                                        .frame(width: 50, height: 5)
                                        .padding(.top, 15)
                                        .padding(.bottom, 5)
                                    Text("Is short: \(controller.isShortCard ? "Yes." : "No.") \(geo.size.width)pt")
                                    Text("Height: \(controller.height)")
                                    Text("XPos: \(controller.xPos)")
                                }
                                .background(
                                    GeometryReader { viewGeo in
                                        Color.clear
                                            .onAppear {
                                                controller.viewHeight = viewGeo.size.height
                                            }
                                    }
                                )
                            }
                            .scrollDisabled(true)
                        }
                        .clipped()
                        .gesture(drawerDrag)
                        .onChange(of: geo.safeAreaInsets) { insets in
                            let sizeCalculation: CGSize = CGSize(
                                width: geo.size.width,
                                height: geo.size.height + (controller.isShortCard ? -insets.bottom : insets.bottom)
                            )
                            controller.calculateIsShortCard(size: geo.size)
                            controller.calculateAvailableHeights(screenSize: sizeCalculation)
                            controller.calculateAvailableWidths(screenSize: sizeCalculation)
                            controller.snapToPoint()
                        }
                        .onAppear {
                            let sizeCalculation: CGSize = CGSize(
                                width: geo.size.width,
                                height: geo.size.height + (controller.isShortCard ? -geo.safeAreaInsets.bottom : geo.safeAreaInsets.bottom)
                            )
                            controller.calculateIsShortCard(size: geo.size)
                            controller.calculateAvailableHeights(screenSize: sizeCalculation)
                            controller.calculateAvailableWidths(screenSize: sizeCalculation)
                            controller.snapToPoint()
                        }
                }
                .offset(
                    x: controller.isShortCard ? controller.xPos : 0,
                    y: geo.size.height - controller.height
                )
            }
            .ignoresSafeArea(edges: controller.isShortCard ? [] : .bottom)
        }
    }
}

@available(iOS 16.0, macOS 13.0, *)
#Preview {
    var colors: [Color] = [.blue, .yellow, .purple, .pink, .red, .brown, .cyan, .gray, .green]
    let color1 = colors.randomElement()!
    colors.remove(at: colors.firstIndex(of: color1)!)
    let color2 = colors.randomElement()!
    
    return ZStack {
        LinearGradient(gradient: Gradient(colors: [color1, color2]), startPoint: .topLeading, endPoint: .bottomTrailing)
            .ignoresSafeArea()
        
        BottomDrawer(
            verticalDetents: [.small, .medium, .large, .view],
            horizontalDetents: [.left, .right, .center]
        )
    }
}
