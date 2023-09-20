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
    private let minDragDistance: CGFloat = 80
    
    var transparency: CGFloat {
        get {
            if controller.availableHeights.isEmpty { return 0 }
            let maxHeight = controller.availableHeights[controller.availableHeights.count - 1]
            let fadeAtPercent = 0.75
            let maxFade = 0.5
            return ((controller.height - maxHeight * fadeAtPercent) / (maxHeight * (1 - fadeAtPercent)) * maxFade).clamped(to: 0...maxFade)
        }
    }
    
    var drawerDrag: some Gesture {
        DragGesture(coordinateSpace: .global)
            .onChanged { update in
                withAnimation(.easeInOut(duration: 0.05)) {
                    controller.height -= update.translation.height - currentDrawerDrag.height
                    controller.xPos += controller.isShortCard && abs(update.translation.width) >= minDragDistance ? update.translation.width - currentDrawerDrag.width : 0
                }
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
        ZStack {
            if !controller.isShortCard {
                Color.black
                    .opacity(transparency)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }
            GeometryReader { geo in
                VStack {
                    Spacer(minLength: geo.size.height - controller.height + geo.safeAreaInsets.top + geo.safeAreaInsets.bottom)
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .foregroundStyle(.regularMaterial)
                        .shadow(radius: 2)
                        .frame(
                            width: controller.isShortCard ? controller.shortCardSize : geo.size.width,
                            height: controller.height
                        )
                        .overlay(
                            content: {
                                VStack {
                                    VStack {
                                        Capsule()
                                            .foregroundStyle(.gray)
                                            .frame(width: 50, height: 5)
                                            .padding(.top, 15)
                                            .padding(.bottom, 5)
                                        Text("Is short: \(controller.isShortCard ? "Yes." : "No.") \(geo.size.width)pt")
                                        Text("Height: \(controller.height)")
                                    }
                                    .background(
                                        GeometryReader { viewGeo in
                                            Color.clear
                                                .onAppear {
                                                    controller.viewHeight = viewGeo.size.height
                                                }
                                        }
                                    )
                                    Spacer()
                                }
                            })
                        .clipped()
                        .gesture(drawerDrag)
                        .onChange(of: geo.size) { size in
                            let sizeCalculation: CGSize = CGSize(width: size.width, height: size.height + geo.safeAreaInsets.bottom)
                            controller.calculateIsShortCard(size: size)
                            controller.calculateAvailableHeights(screenSize: sizeCalculation)
                            controller.calculateAvailableWidths(screenSize: sizeCalculation)
                        }
                        .onAppear {
                            let sizeCalculation: CGSize = CGSize(width: geo.size.width, height: geo.size.height + geo.safeAreaInsets.bottom)
                            controller.calculateIsShortCard(size: geo.size)
                            controller.calculateAvailableHeights(screenSize: sizeCalculation)
                            controller.calculateAvailableWidths(screenSize: sizeCalculation)
                        }
                }
                .padding(.leading, geo.safeAreaInsets.leading)
                .padding(.trailing, geo.safeAreaInsets.trailing)
                .ignoresSafeArea()
            }
        }
        .offset(x: controller.isShortCard ? controller.xPos : 0)
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
