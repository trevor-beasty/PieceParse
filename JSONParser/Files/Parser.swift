//
//  Parser.swift
//  JSONParser
//
//  Created by Trevor Beasty on 8/9/19.
//  Copyright © 2019 Trevor Beasty. All rights reserved.
//

import Foundation

struct Parser<A> {
    let run: (Container) throws -> A
}

typealias Container = KeyedDecodingContainer<AnonymousCodingKey>

extension Parser {
    
    func run(_ data: Data) throws -> A {
        let anonymousContainer = try JSONDecoder().decode(AnonymousContainer.self, from: data)
        return try run(anonymousContainer.container)
    }
    
}

func parseValue<A: Decodable>(_ type: A.Type, key: String) -> Parser<A> {
    return Parser { cont in
        return try cont.decode(type, forKey: .init(key))
    }
}

func nestedContainer(key: String) -> Parser<Container> {
    return Parser { cont in
        return try cont.nestedContainer(keyedBy: AnonymousCodingKey.self, forKey: .init(key))
    }
}

func nestedContainer(path: String...) -> Parser<Container> {
    return Parser { cont in
        var _cont = cont
        for key in path {
            _cont = try nestedContainer(key: key).run(_cont)
        }
        return _cont
    }
}

// MARK: - Functional

extension Parser {
    
    func map<B>(_ f: @escaping (A) -> B) -> Parser<B> {
        return Parser<B> { cont in
            f(try self.run(cont))
        }
    }
    
    func chain<B>(_ b: Parser<B>) -> Parser<B> where A == Container {
        return Parser<B> { cont in
            let contA = try self.run(cont)
            return try b.run(contA)
        }
    }
    
}

func zip<A, B>(_ a: Parser<A>, _ b: Parser<B>) -> Parser<(A, B)> {
    return Parser { cont in
        let parsedA = try a.run(cont)
        let parsedB = try b.run(cont)
        return (parsedA, parsedB)
    }
}
