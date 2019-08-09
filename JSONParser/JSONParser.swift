//
//  JSONParser.swift
//  JSONParser
//
//  Created by Trevor Beasty on 8/9/19.
//  Copyright © 2019 Trevor Beasty. All rights reserved.
//

import Foundation

struct Parser<T> {
    let run: (Container) throws -> T
}

protocol Parsable: Decodable {
    static var parser: Parser<Self> { get }
}

extension Parsable {
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: AnonymousCodingKey.self)
        self = try Self.parser.run(container)
    }
    
}

func value<T: Decodable>(_ type: T.Type, key: String) -> Parser<T> {
    return Parser { container in
        return try container.decode(type, forKey: .init(key))
    }
}

func nestedContainer(key: String) -> Parser<Container> {
    return Parser { container in
        return try container.nestedContainer(keyedBy: AnonymousCodingKey.self, forKey: .init(key))
    }
}

struct AnonymousCodingKey: CodingKey {
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

typealias Container = KeyedDecodingContainer<AnonymousCodingKey>
