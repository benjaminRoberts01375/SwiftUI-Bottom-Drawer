// Created on 9/14/23 by Ben Roberts
// Created for the Bottom Drawer library
//
// Swift 5.0
//

import SwiftUI

@available(iOS 16.0, macOS 13.0, *)
public struct BottomDrawer: View {
    private let cornerRadius = 20
    @StateObject private var controller: BottomDrawerVM
    
    public init(detents: Set<Detents>) {
        self._controller = StateObject(
            wrappedValue: BottomDrawerVM(detents: detents)
        )
    }
    
    public var body: some View {
        GeometryReader { geo in
            VStack {
                Spacer()
                VStack {
                    Text("Test")
                    Spacer()
                }
                .frame(width: geo.size.width, height: 500)
                .background(.white)
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
