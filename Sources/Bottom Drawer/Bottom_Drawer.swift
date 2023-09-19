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
    @Environment(\.colorScheme) var colorScheme
    @State var currentDrawerDrag: CGFloat = 0
    
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
                    controller.height -= update.translation.height - currentDrawerDrag
                    if controller.height < 0 {
                        controller.height = 0
                    }
                }
                currentDrawerDrag = update.translation.height
            }
            .onEnded { update in
                controller.snapToPoint(velocity: update.velocity.height)
                currentDrawerDrag = 0
            }
    }
    
    public init(detents: Set<Detents>) {
        self._controller = StateObject(
            wrappedValue: BottomDrawerVM(detents: detents)
        )
    }
    
    public var body: some View {
        ZStack {
            Color.black
                .opacity(transparency)
                .allowsHitTesting(false)
            GeometryReader { geo in
                VStack {
                    Spacer(minLength: geo.size.height - controller.height)
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .foregroundStyle(.regularMaterial)
                        .shadow(radius: 2)
                        .frame(height: controller.height)
                        .overlay(
                            content: {
                                VStack {
                                    VStack {
                                        Capsule()
                                            .foregroundStyle(.gray)
                                            .frame(width: 50, height: 5)
                                            .padding(.top, 15)
                                            .padding(.bottom, 5)
                                        Text("View height: \(controller.viewHeight)")
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
                        .onChange(of: geo) { newGeo in
                            let width: CGFloat = newGeo.safeAreaInsets.leading + newGeo.safeAreaInsets.trailing + newGeo.size.width
                            let height: CGFloat = newGeo.safeAreaInsets.top + newGeo.safeAreaInsets.bottom + newGeo.size.height
                            controller.calculateAvailableHeights(
                                screenSize: CGSize(
                                    width: width,
                                    height: height
                                )
                            )
                        }
                        .onAppear {
                            controller.calculateAvailableHeights(
                                screenSize: CGSize(
                                    width: geo.size.width + geo.safeAreaInsets.leading + geo.safeAreaInsets.trailing,
                                    height: geo.size.height + geo.safeAreaInsets.top + geo.safeAreaInsets.bottom
                                )
                            )
                        }
                }
            }
        }
        .ignoresSafeArea()
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
        
        BottomDrawer(detents: [.small, .medium, .large, .view])
    }
}
