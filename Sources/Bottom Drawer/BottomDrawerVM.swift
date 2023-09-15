// Created on 9/15/23 by Ben Roberts
// Created for the Bottom Drawer library
//
// Swift 5.0
//

import SwiftUI

final class BottomDrawerVM: ObservableObject {
    private let detents: Set<PresentationDetent>
    
    init(detents: Set<PresentationDetent>) {
        self.detents = detents
    }
}
