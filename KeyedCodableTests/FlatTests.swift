//
//  FlatTests.swift
//  KeyedCodableTests
//
//  Created by Dariusz Grzeszczak on 11/05/2018.
//

import KeyedCodable
import XCTest

private let jsonString = """
{
    "inner": {
        "greeting": "hallo"
    },
    "longitude": 3.2,
    "latitude": 3.4
}
"""

struct Location: Codable {
    let latitude: Double
    let longitude: Double?
}

struct InnerWithFlatExample: Codable {
    let greeting: String
    let location: Location?

    enum CodingKeys: String, KeyedKey {
        case greeting = "inner.greeting"
        case location = ""
    }
}

#if swift(>=5.1)
struct InnerWithFlatWrapperExample: Codable {
    let greeting: String
    @Flat private(set) var location: Location?

    enum CodingKeys: String, KeyedKey {
        case greeting = "inner.greeting"
        case location
    }
}

struct InnerWithFlatWrapperAndTransformExample: Codable {
    let greeting: String
    @FlatCodedBy<LocationTransformer> private(set) var location: Location?

    enum CodingKeys: String, KeyedKey {
        case greeting = "inner.greeting"
        case location
    }
}

struct IntermediateLocation: Codable {
    var interLat: Double
    var interLon: Double
}

struct LocationTransformer: Transformer {
    typealias Destination = IntermediateLocation
    
    static func transform(from decodable: IntermediateLocation) throws -> Any? {
        return Location(latitude: decodable.interLat, longitude: decodable.interLon)
    }
    
    static func transform(object: Location?) throws -> IntermediateLocation? {
        guard let object = object,
              let longitude = object.longitude else { return nil }
        return IntermediateLocation(interLat: object.latitude, interLon: longitude)
    }
    
    typealias Source = IntermediateLocation
    
    typealias Object = Location?
}
#endif

class FlatTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testFlat() {
        let jsonData = jsonString.data(using: .utf8)!

        KeyedCodableTestHelper.checkEncode(data: jsonData, checkString: false) { (test: InnerWithFlatExample) in
            XCTAssert(test.greeting == "hallo")
            XCTAssert(test.location?.latitude == 3.4)
            XCTAssert(test.location?.longitude == 3.2)
        }
    }

    #if swift(>=5.1)
    func testFlatWrapper() {
        let jsonData = jsonString.data(using: .utf8)!

        KeyedCodableTestHelper.checkEncode(data: jsonData, checkString: false) { (test: InnerWithFlatWrapperExample) in
            XCTAssert(test.greeting == "hallo")
            XCTAssert(test.location?.latitude == 3.4)
            XCTAssert(test.location?.longitude == 3.2)
        }
    }
    
    func testFlatDecodedByWrapper() throws {
        let json = """
        {
            "inner": {
                "greeting": "hallo"
            },
            "interLat": 3.2,
            "interLon": 3.4
        }
        """.data(using: .utf8)!
        
        KeyedCodableTestHelper.checkEncode(data: json, checkString: false) { (test: InnerWithFlatWrapperAndTransformExample) in
            XCTAssert(test.greeting == "hallo")
            XCTAssert(test.location?.latitude == 3.2)
            XCTAssert(test.location?.longitude == 3.4)
        }
    }
    #endif
}
