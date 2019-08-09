//
//  JSONParserTests.swift
//  JSONParserTests
//
//  Created by Trevor Beasty on 8/9/19.
//  Copyright © 2019 Trevor Beasty. All rights reserved.
//

import XCTest
@testable import JSONParser

class JSONParserTests: XCTestCase {
    
    func test() throws {
        let data = try jsonData("Food")
        
        let parser = JSONParser.value(String.self, key: "name")
        let result = try parser.run(data)
        
        XCTAssertEqual(result, "toast")
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
