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

class JSONParserTests: XCTestCase {
    
    func test_Food_SingleFlat() throws {
        let data = try jsonData("Food")
        
        let parser = parseValue(String.self, key: "name")
        
        let result = try parser.run(data)
        XCTAssertEqual(result, "toast")
    }
    
    func test_Food_MultipleFlat() throws {
        let data = try jsonData("Food")
        
        let parser = zip(parseValue(String.self, key: "name"),
                         parseValue(Int.self, key: "points"))
            .map(Food.init)
        
        let food = try parser.run(data)
        XCTAssertEqual(food, Food.init(name: "toast", points: 2))
    }
    
//    func test_HeterogenousList() {
//        let data = try jsonData("SearchResults")
//
//        let parser =
//    }
    
    func test_NestedValue() throws {
        let data = try jsonData("NestedValue")
        
        let parser = nestedContainer(key: "success")
            .chain(nestedContainer(key: "result"))
            .chain(parseValue(Int.self, key: "value"))
        
        let value = try parser.run(data)
        XCTAssertEqual(value, 4)
    }
    
    func test_NestedValue_WithNestedContainerPath() throws {
        let data = try jsonData("NestedValue")
        
        let parser = nestedContainer(path: "success", "result")
            .chain(parseValue(Int.self, key: "value"))
        
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
                nestedContainer(key: "result").chain(parseValue(Int.self, key: "value")),
                parseValue(Bool.self, key: "winner")
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
