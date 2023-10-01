// Created on 9/14/23 by Ben Roberts
// Created for the Bottom Drawer library
//
// Swift 5.0
//

import SwiftUI

@available(iOS 16.0, macOS 13.0, *)
public struct BottomDrawer: View {
    private let cornerRadius: CGFloat = 20
    @StateObject private var controller: BottomDrawerVM
    @State private var currentDrawerDrag: CGSize = .zero
    @State private var allowScrolling = false
    
    private var transparency: CGFloat {
        if controller.availableHeights.isEmpty { return 0 }
        let maxHeight = controller.availableHeights[controller.availableHeights.count - 1]
        let fadeAtPercent = 0.75
        let maxFade = 0.5
        return ((controller.height - maxHeight * fadeAtPercent) / (maxHeight * (1 - fadeAtPercent)) * maxFade).clamped(to: 0...maxFade)
    }
    
    private var drawerDrag: some Gesture {
        DragGesture(coordinateSpace: .global)
            .onChanged { update in
                if !allowScrolling {
                    allowScrolling = true
                    return
                }
                
                let dampening = { (distancePast: CGFloat) -> CGFloat in
                    let distance = pow(abs(distancePast), 1 / 1.5)
                    return distancePast < 0 ? -distance : distance
                }
                controller.calculateY(heightDelta: update.translation.height - currentDrawerDrag.height, dampening: dampening)
                controller.calculateX(dragValue: update, currentDrawerDrag: currentDrawerDrag, dampening: dampening)
                currentDrawerDrag = update.translation
            }
            .onEnded { update in
                controller.snapToPoint(velocity: update.velocity)
                controller.calculateScrollable()
                currentDrawerDrag = .zero
                allowScrolling = false
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
                            VStack {
                                Button {
                                    guard let maxSnapPoint = controller.availableHeights.max(),
                                          let minSnapPoint = controller.availableHeights.min()
                                    else { return }
                                    withAnimation(.bouncy(duration: 0.5)) {
                                        controller.height = controller.height == maxSnapPoint ? minSnapPoint : maxSnapPoint
                                    }
                                    controller.calculateScrollable()
                                } label: {
                                    Capsule()
                                        .foregroundStyle(.gray)
                                        .frame(width: 50, height: 5)
                                        .padding(.top, 15)
                                        .padding(.bottom, 5)
                                        .gesture(drawerDrag)
                                }
                                ScrollView {
                                    VStack {
                                        Text("Is short: \(controller.isShortCard ? "Yes." : "No.") \(geo.size.width)pt")
                                        Text("Height: \(controller.height)")
                                        Text("XPos: \(controller.xPos)")
                                        Text("Scrollable: \(controller.scrollable ? "true" : "false")")
                                        Color.yellow
                                            .frame(width: 100, height: 800)
                                    }
                                    .frame(width: geo.size.width)
                                    .background(
                                        GeometryReader { viewGeo in
                                            Color.clear
                                                .onAppear {
                                                    controller.viewHeight = viewGeo.size.height
                                                }
                                        }
                                    )
                                }
                                .scenePadding([.bottom])
                                .scrollDisabled(!controller.scrollable)
                            }
                        }
                        .clipped()
                        .gesture(drawerDrag)
                        .onChange(of: geo.safeAreaInsets) { controller.recalculateAll(size: geo.size, safeAreas: $0) }
                        .onAppear { controller.recalculateAll(size: geo.size, safeAreas: geo.safeAreaInsets) }
                }
                .offset(
                    x: controller.isShortCard ? controller.xPos : 0,
                    y: geo.size.height - controller.height + (controller.isShortCard ? 0 : geo.safeAreaInsets.bottom)
                )
            }
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
