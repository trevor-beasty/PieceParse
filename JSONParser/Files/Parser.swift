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

enum JSONParserError<A>: Error {
    case oneOfFailed(failures: [(Parser<A>, Error)], container: Container)
}

typealias Container = KeyedDecodingContainer<AnonymousCodingKey>

extension Parser {
    
    func run(_ data: Data) throws -> A {
        let anonymousContainer = try JSONDecoder().decode(AnonymousContainer.self, from: data)
        return try run(anonymousContainer.container)
    }
    
}

func parse<A: Decodable>(_ type: A.Type, key: String) -> Parser<A> {
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

func oneOf<A>(_ ps: [Parser<A>]) -> Parser<A> {
    return Parser<A> { cont in
        var failures = [(Parser<A>, Error)]()
        for p in ps {
            do {
                return try p.run(cont)
            }
            catch let error {
                failures.append((p, error))
            }
        }
        throw JSONParserError.oneOfFailed(failures: failures, container: cont)
    }
}

func parseMany<A>(with p: Parser<A>, key: String) -> Parser<[A]> {
    return Parser<[A]> { cont in
        var unkeyedCont = try cont.nestedUnkeyedContainer(forKey: .init(key))
        var parsed = [A]()
        while !unkeyedCont.isAtEnd {
            let cont = try unkeyedCont.nestedContainer(keyedBy: AnonymousCodingKey.self)
            let a = try p.run(cont)
            parsed.append(a)
        }
        return parsed
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
            try b.run(try self.run(cont))
        }
    }
    
    func chain<B, C>(_ b: Parser<B>, _ c: Parser<C>) -> Parser<(B, C)> where A == Container {
        return Parser<(B, C)> { cont in
            let contA = try self.run(cont)
            return (try b.run(contA), try c.run(contA))
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
