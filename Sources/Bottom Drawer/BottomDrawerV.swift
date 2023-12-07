// Created on 9/14/23 by Ben Roberts
// Created for the Bottom Drawer library
//
// Swift 5.0
//

import SwiftUI

@available(iOS 16.0, macOS 13.0, *)
public struct BottomDrawer: View {
    /// Corner radius of the drawer.
    private let cornerRadius: CGFloat = 20
    @StateObject private var controller: BottomDrawerVM
    /// Distance dragged throughout the drag gesture.
    @State private var currentDrawerDrag: CGSize = .zero
    /// Used to determine if there was an incorrect application of the drag gesture for a single frame.
    @State private var oneFrameDragSkipped = false
    /// Determine if we should use the change in geo or change in safe area.
    @State private var useChangeSize = true
    #if os(macOS)
    /// Track the state of the bottom drawer button.
    @FocusState private var isButtonFocused
#endif
    /// View to render above the content.
    private var header: ((Bool) -> any View)?
    /// Content to render in the drawer.
    private var content: (Bool) -> any View
    /// Name space for the area inside of the scroll view.
    let scrollNameSpace = "scroll"
    
    @State var showingKeyboard: Bool = false
    
    /// Transparency of the black layer behind the bottom drawer.
    private var transparency: CGFloat {
        if controller.availableHeights.count <= 1 { return 0 }
        if controller.availableHeights.last ?? 0 < 500 { return 0 }
        let maxHeight = controller.availableHeights[controller.availableHeights.count - 1]
        let fadeAtPercent = 0.75
        let maxFade = 0.5
        return ((controller.height - maxHeight * fadeAtPercent) / (maxHeight * (1 - fadeAtPercent)) * maxFade).clamped(to: 0...maxFade)
    }
    
    /// Gesture used for moving the drawer up, down, left, and right.
    private var drawerDrag: some Gesture {
        DragGesture(coordinateSpace: .global)
            .onChanged { update in
                if !oneFrameDragSkipped {
                    oneFrameDragSkipped = true
                    return
                }
                
                let dampening = { (distancePast: CGFloat) -> CGFloat in
                    let distance = pow(abs(distancePast), 1 / 1.5)
                    return distancePast < 0 ? -distance : distance
                }
                controller.calculateHeight(heightDelta: update.translation.height - currentDrawerDrag.height, dampening: dampening)
                controller.calculateX(dragValue: update, currentDrawerDrag: currentDrawerDrag, dampening: dampening)
                currentDrawerDrag = update.translation
            }
            .onEnded { update in
                controller.snapToPoint(velocity: update.velocity)
                controller.calculateScrollable()
                currentDrawerDrag = .zero
                oneFrameDragSkipped = false
            }
    }
    
    /// Create a bottom drawer with detents and displayed content
    /// - Parameters:
    ///   - verticalDetents: Snap points for the height of the drawer.
    ///   - horizontalDetents: Snap points in the horizontal direction.
    ///   - content: Content to show on the bottom drawer
    public init(
        verticalDetents: Set<VerticalDetents>,
        horizontalDetents: Set<HorizontalDetents>,
        preventScrolling: Bool = false,
        shortCardSize: CGFloat = 300,
        header: ((Bool) -> any View)? = nil,
        @ViewBuilder content: @escaping (Bool) -> any View
    ) {
        self._controller = StateObject(
            wrappedValue: BottomDrawerVM(
                verticalDetents: verticalDetents,
                horizontalDetents: horizontalDetents,
                preventScrolling: preventScrolling,
                shortCardSize: shortCardSize
            )
        )
        self.header = header
        self.content = content
    }
    
    public var body: some View {
        ZStack(alignment: .bottomTrailing) {
            if !controller.isShortDrawer {
                Color.black
                    .opacity(transparency)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }
            GeometryReader { geo in
                VStack {
                    if controller.verticalDetents.count > 1 || controller.horizontalDetents.count > 1 {
                        Button {
                            controller.buttonSnap()
                            controller.calculateScrollable()
                        } label: {
                            Capsule()
                                .frame(width: 50, height: 5)
                                .gesture(drawerDrag)
                                .padding(.top, 15)
                                .padding(.bottom, 5)
                                #if os(macOS)
                                .animation(.linear, value: isButtonFocused)
                                .foregroundStyle(isButtonFocused ? .black : .gray)
                                #endif
                                .foregroundStyle(.gray)
                        }
                        .buttonStyle(.borderless)
                        #if os(macOS)
                        .focused($isButtonFocused)
                        #endif
                    }
                    if let header = header {
                        AnyView(header(controller.isShortDrawer))
                            .background(
                                GeometryReader { headerGeo in
                                    Color.clear
                                        .onAppear {
                                            controller.headerHeight = headerGeo.size.height
                                            controller.recalculateAll(size: geo.size, safeAreas: geo.safeAreaInsets)
                                        }
                                        .onChange(of: headerGeo.size) { newGeo in
                                            controller.headerHeight = newGeo.height
                                            controller.recalculateAll(size: geo.size, safeAreas: geo.safeAreaInsets)
                                        }
                                }
                            )
                    }
                    ScrollView {
                        AnyView(content(controller.isShortDrawer))
                            .padding(.top, controller.verticalDetents.count > 1 || controller.horizontalDetents.count > 1 ? 0 : 10)
                        .background(
                            GeometryReader { contentGeo in
                                Color.clear
                                    .onAppear {
                                        controller.contentHeight = contentGeo.size.height
                                        controller.recalculateAll(size: geo.size, safeAreas: geo.safeAreaInsets)
                                    }
                                    .onChange(of: contentGeo.size) { newGeo in
                                        controller.contentHeight = newGeo.height
                                        controller.recalculateAll(size: geo.size, safeAreas: geo.safeAreaInsets)
                                    }
                                    .preference(key: ScrollOffsetPreferenceKey.self, value: contentGeo.frame(in: .named(scrollNameSpace)).origin)
                            }
                        )
                        .opacity(controller.contentOpacity)
                    }
                    .coordinateSpace(name: scrollNameSpace)
                    .scenePadding(controller.isShortDrawer ? [] : [.bottom])
                    .scrollDisabled(!controller.scrollable)
                }
                .onAppear {
                    NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: .main) { _ in // Add observer for keeping track of keyboard raising
                        self.showingKeyboard = true
                    }
                    NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: .main) { _ in // Add observer for keeping track of keyboard hiding
                        self.showingKeyboard = false
                    }
                }
                .drawerLayer(
                    cornerRadii: RectangleCornerRadii(
                        topLeading: cornerRadius,
                        bottomLeading: showingKeyboard || (controller.isShortDrawer && geo.safeAreaInsets.bottom > 0) ? cornerRadius : 0,
                        bottomTrailing: showingKeyboard || (controller.isShortDrawer && geo.safeAreaInsets.bottom > 0) ? cornerRadius : 0,
                        topTrailing: cornerRadius
                    )
                )
                .padding(.leading, controller.isShortDrawer && geo.safeAreaInsets.leading < geo.safeAreaInsets.bottom && !showingKeyboard ? abs(geo.safeAreaInsets.leading - geo.safeAreaInsets.bottom) : 0)
                .padding(.trailing, controller.isShortDrawer && geo.safeAreaInsets.trailing < geo.safeAreaInsets.bottom && !showingKeyboard ? abs(geo.safeAreaInsets.trailing - geo.safeAreaInsets.bottom): 0)
                .frame(
                    width: controller.isShortDrawer ? controller.shortDrawerSize : geo.size.width,
                    height: controller.height
                )
                .gesture(drawerDrag)
                .onChange(of: geo.safeAreaInsets) {
                    controller.recalculateAll(size: geo.size, safeAreas: $0)
                    if useChangeSize { useChangeSize = false }
                }
                .onChange(of: geo.size) { if useChangeSize { controller.recalculateAll(size: $0, safeAreas: geo.safeAreaInsets) } }
                .onAppear { controller.recalculateAll(size: geo.size, safeAreas: geo.safeAreaInsets) }
                .onPreferenceChange(ScrollOffsetPreferenceKey.self) { _ in if oneFrameDragSkipped { oneFrameDragSkipped = false } }
                .offset(
                    x: controller.isShortDrawer ? controller.xPos : 0,
                    y: geo.size.height - controller.height + (controller.isShortDrawer || showingKeyboard ? 0 : geo.safeAreaInsets.bottom)
                )
            }
        }
    }
}

struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGPoint = .zero
    
    static func reduce(value: inout CGPoint, nextValue: () -> CGPoint) {
        defaultValue = nextValue()
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
            verticalDetents: [.small, .medium, .large, .content],
            horizontalDetents: [.left, .right, .center]
        ) { shortCardStatus in
            VStack {
                Text("Content")
                Text("Is short card: \(shortCardStatus.description)")
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
            verticalDetents: [.small],
            horizontalDetents: [.left]
        ) { shortCardStatus in
            VStack {
                Text("Content")
                Text("Is short card: \(shortCardStatus.description)")
            }
        }
    }
}
