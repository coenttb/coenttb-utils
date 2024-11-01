//
//  File.swift
//  coenttb-utils
//
//  Created by Coen ten Thije Boonkkamp on 01/11/2024.
//

import Foundation

extension Array {
    public init(@ArrayBuilder<Element> _ builder: () -> [Element]) {
        self = builder()
    }
}

