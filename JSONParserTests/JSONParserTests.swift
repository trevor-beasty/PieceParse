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
    
//    func test_HeterogenousList() throws {
//        let data = try jsonData("SearchResults")
//
//        let parser =
//    }
    
    func test_List() throws {
        let data = try jsonData("UniformSearchResults")
        
        let parser = parseMany(with: foodParser, key: "results")
        
        let result = try parser.run(data)
        let food0 = Food.init(name: "banana", points: 0)
        let food1 = Food.init(name: "hamburger", points: 8)
        XCTAssertEqual(result, [food0, food1])
    }
    
    func test_NestedValue() throws {
        let data = try jsonData("NestedValue")
        
        let parser = nestedContainer(key: "success")
            .chain(nestedContainer(key: "result"))
            .chain(parse(Int.self, key: "value"))
        
        let value = try parser.run(data)
        XCTAssertEqual(value, 4)
    }
    
    func test_NestedValue_WithNestedContainerPath() throws {
        let data = try jsonData("NestedValue")
        
        let parser = nestedContainer(path: "success", "result")
            .chain(parse(Int.self, key: "value"))
        
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
            .chain(
                nestedContainer(key: "result").chain(parse(Int.self, key: "value")),
                parse(Bool.self, key: "winner")
            )
            .map(Model.init)
        
        let result = try parser.run(data)
        XCTAssertEqual(result, Model.init(value: 4, winner: true))
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
