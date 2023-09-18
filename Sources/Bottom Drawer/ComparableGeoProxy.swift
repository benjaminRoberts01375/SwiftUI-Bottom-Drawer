//
//  File.swift
//  
//
//  Created by Ben Roberts on 9/18/23.
//

import SwiftUI

extension GeometryProxy: Comparable {
    public static func < (lhs: GeometryProxy, rhs: GeometryProxy) -> Bool {
        return lhs.size.width * lhs.size.height < rhs.size.width * rhs.size.height
    }
    
    public static func == (lhs: GeometryProxy, rhs: GeometryProxy) -> Bool {
        return lhs.size == rhs.size && lhs.safeAreaInsets == rhs.safeAreaInsets
    }
}
