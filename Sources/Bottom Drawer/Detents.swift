// Created on 9/16/23 by Ben Roberts
// Created for the Bottom Drawer library
//
// Swift 5.0
//

import Foundation

public enum VerticalDetents: Hashable {
    case small
    case medium
    case large
    case fraction(CGFloat)
    case exactly(CGFloat)
    case view
}

public enum HorizontalDetents: Hashable {
    case left
    case right
    case center
}
