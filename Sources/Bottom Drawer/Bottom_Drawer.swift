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
    private var capsuleShadowRadius: CGFloat {
        colorScheme == .dark ? 2 : 1
    }
    @StateObject private var controller: BottomDrawerVM
    @Environment(\.colorScheme) var colorScheme
    @State var height: CGFloat = 200
    @State var currentDrawerDrag: CGFloat = 0
    
    var drawerDrag: some Gesture {
        DragGesture(coordinateSpace: .global)
            .onChanged { update in
                height -= update.translation.height - currentDrawerDrag
                currentDrawerDrag = update.translation.height
                
                if height < 0 {
                    height = 0
                }
                print(height)
            }
            .onEnded { update in
                currentDrawerDrag = 0
            }
    }
    
    public init(detents: Set<Detents>) {
        self._controller = StateObject(
            wrappedValue: BottomDrawerVM(detents: detents)
        )
    }
    
    public var body: some View {
        GeometryReader { geo in
            VStack {
                Spacer()
                RoundedRectangle(cornerRadius: cornerRadius)
                    .foregroundStyle(.regularMaterial.shadow(.inner(color: .black.opacity(0.3), radius: shadowRadius)))
                    .shadow(radius: 2)
                    .frame(height: height)
                    .overlay(content: {
                        VStack {
                            Capsule()
                                .foregroundStyle(.gray)
                                .frame(width: 50, height: 5)
                                .padding(.top, 15)
                                .padding(.bottom, 5)
                                .shadow(radius: capsuleShadowRadius)
                            Text("Placeholder View")
                            Spacer()
                        }
                    })
                    .clipped()
                    .offset(y: geo.safeAreaInsets.bottom)
                    .gesture(drawerDrag)
                    .onChange(of: geo.size) { size in
                        controller.calculateAvailableHeights(screenSize: size)
                    }
                    .onAppear {
                        controller.calculateAvailableHeights(screenSize: geo.size)
                    }
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
        
        BottomDrawer(detents: [.fraction(1/2)])
    }
}
