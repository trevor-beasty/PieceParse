//
//  Internal.swift
//  JSONParser
//
//  Created by Trevor Beasty on 8/9/19.
//  Copyright © 2019 Trevor Beasty. All rights reserved.
//

import Foundation

internal struct AnonymousContainer: Decodable {
    let container: Container
    
    init(from decoder: Decoder) throws {
        container = try decoder.container(keyedBy: AnonymousCodingKey.self)
    }
}

internal struct AnonymousCodingKey: CodingKey {
    let stringValue: String
    var intValue: Int? { return nil }
    
    init(_ key: String) {
        self.stringValue = key
    }
    
    init?(stringValue: String) {
        self.stringValue = stringValue
    }
    
    init?(intValue: Int) {
        return nil
    }
    
}
