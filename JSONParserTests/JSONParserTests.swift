//
//  JSONParserTests.swift
//  JSONParserTests
//
//  Created by Trevor Beasty on 8/9/19.
//  Copyright © 2019 Trevor Beasty. All rights reserved.
//

import XCTest
@testable import JSONParser

struct Food: Equatable {
    let name: String
    let points: Int
}

struct User: Equatable {
    let id: String
    let userName: String
}

let foodParser = zip(parse(String.self, key: "name"),
                     parse(Int.self, key: "points"))
    .map(Food.init)

let userParser = zip(parse(String.self, key: "_id"),
                     parse(String.self, key: "userName"))
    .map(User.init)

class JSONParserTests: XCTestCase {
    
    func test_Food_SingleFlat() throws {
        let data = try jsonData("Food")
        
        let parser = parse(String.self, key: "name")
        
        let result = try parser.run(data)
        XCTAssertEqual(result, "toast")
    }
    
    func test_Food_MultipleFlat() throws {
        let data = try jsonData("Food")
        
        let food = try foodParser.run(data)
        XCTAssertEqual(food, Food.init(name: "toast", points: 2))
    }
    
    func test_List() throws {
        let data = try jsonData("UniformSearchResults")
        
        let parser = parseList(with: foodParser, key: "results")
        
        let result = try parser.run(data)
        let food0 = Food.init(name: "banana", points: 0)
        let food1 = Food.init(name: "hamburger", points: 8)
        XCTAssertEqual(result, [food0, food1])
    }
    
    func test_HeterogenousList() throws {
        
        enum Item: Equatable {
            case food(Food)
            case user(User)
        }
        
        let data = try jsonData("MixedSearchResults")
        
        let itemParser: Parser<Item> = oneOf([foodParser.map { .food($0) },
                                              userParser.map { .user($0) }])
        
        let parser = parseList(with: itemParser, key: "results")
        
        let result = try parser.run(data)
        XCTAssertEqual(result, [Item.food(.init(name: "banana", points: 0)),
                                Item.user(.init(id: "abc123", userName: "blob"))])
    }
    
    func test_NestedValue() throws {
        let data = try jsonData("NestedValue")
        
        let parser = nestedContainer(key: "success")
            .flatMap(nestedContainer(key: "result"))
            .flatMap(parse(Int.self, key: "value"))
        
        let value = try parser.run(data)
        XCTAssertEqual(value, 4)
    }
    
    func test_NestedValue_WithNestedContainerPath() throws {
        let data = try jsonData("NestedValue")
        
        let parser = nestedContainer(path: "success", "result")
            .flatMap(parse(Int.self, key: "value"))
        
        let value = try parser.run(data)
        XCTAssertEqual(value, 4)
    }
    
    func test_MultipleNested() throws {
        
        struct Model: Equatable {
            let value: Int
            let winner: Bool
        }
        
        let data = try jsonData("NestedValue")
        
        let parser = nestedContainer(key: "success")
            .flatMap(
                nestedContainer(key: "result").flatMap(parse(Int.self, key: "value")),
                parse(Bool.self, key: "winner")
            )
            .map(Model.init)
        
        let result = try parser.run(data)
        XCTAssertEqual(result, Model.init(value: 4, winner: true))
    }
    
    // This is a style more similar to how the 'keyed container' api operates.
    // The idea here is that plural flatMaps (BC, BCD, etc) may be unneeded.
    func test_MultipleNested_WithoutPluralFlatMap() throws {
        // given
        struct Model: Equatable {
            let value: Int
            let winner: Bool
        }
        
        let data = try jsonData("NestedValue")
        
        // when
        let successCont = try nestedContainer(key: "success").run(data)
        
        let value = try nestedContainer(key: "result")
            .flatMap(parse(Int.self, key: "value"))
            .run(successCont)
        
        let winner = try parse(Bool.self, key: "winner").run(successCont)
        
        let result = Model.init(value: value, winner: winner)
        
        // then
        XCTAssertEqual(result, Model.init(value: 4, winner: true))
    }
    
    func test_StringLiteral() throws {
        
        enum Program: String {
            case programA
            case programB
        }
        
        let data = try jsonData("StringLiteral")
        
        let parser = parse([String].self, key: "values")
            .map({
                return $0.map {
                    return Program.init(rawValue: $0)!
                }
            })
        
        let result = try parser.run(data)
        XCTAssertEqual(result, [.programA, .programB])
    }

    func jsonData(_ fileName: String) throws -> Data {
        let bundle = Bundle.init(for: JSONParserTests.self)
        guard let url = bundle.url(forResource: fileName, withExtension: "json") else {
            throw "url not found; fileName: \(fileName)"
        }
        return try Data.init(contentsOf: url)
    }

}

extension String: Error { }
