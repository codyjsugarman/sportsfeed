//
//  Channel.swift
//  Newsboard
//
//  Created by Kern Khanna on 3/13/17.
//  Copyright © 2017 Kern Khanna. All rights reserved.
//

import Foundation

internal class Channel {
    internal let id: String
    internal let name: String
    
    init(id: String, name: String) {
        self.id = id
        self.name = name
    }
}
