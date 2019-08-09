//
//  Parser.swift
//  JSONParser
//
//  Created by Trevor Beasty on 8/9/19.
//  Copyright © 2019 Trevor Beasty. All rights reserved.
//

import Foundation

struct Parser<T> {
    let run: (Container) throws -> T
}

typealias Container = KeyedDecodingContainer<AnonymousCodingKey>

extension Parser {
    
    func run(_ data: Data) throws -> T {
        let anonymousContainer = try JSONDecoder().decode(AnonymousContainer.self, from: data)
        return try run(anonymousContainer.container)
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
