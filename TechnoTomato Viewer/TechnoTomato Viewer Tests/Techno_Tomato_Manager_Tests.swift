//
//  Techno_Tomato_Manager_Tests.swift
//  Techno Tomato Manager Tests
//
//  Created by DoodleBytes Development on 7/21/19.
//  Copyright © 2019 DoodleBytes Development. All rights reserved.
//

import XCTest

class Techno_Tomato_Manager_Tests: XCTestCase {
    
    let sampleJSON: String = """
{"channel":{"id":772438,"name":"TechnoTomatoPlantsZone1","description":"the leaf sensor and leaf temperature values of the four tomato plants on east end of set.","latitude":"0.0","longitude":"0.0","field1":"Leaf Sensor 1 Diff","field2":"Leaf Sensor 1 Trigger","field3":"Leaf Sensor 2 Diff","field4":"Leaf Sensor 2 Trigger","field5":"Leaf Sensor 3 Diff","field6":"Leaf Sensor 3 Trigger","field7":"Air Temperature","field8":"Root Temperature","created_at":"2019-05-02T15:01:34Z","updated_at":"2019-07-07T13:37:41Z","last_entry_id":20520},"feeds":[{"created_at":"2019-07-21T22:39:44Z","entry_id":20519,"field1":"0.92000","field2":"0.00000","field3":"0.68000","field4":"0.00000","field5":"1.53000","field6":"0.00000","field7":"25.00000","field8":"21.00000"},{"created_at":"2019-07-21T22:40:44Z","entry_id":20520,"field1":"0.74000","field2":"0.00000","field3":"0.53000","field4":"0.00000","field5":"1.69000","field6":"0.00000","field7":"25.00000","field8":"21.00000"}]}
"""

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testThingspeakDataDecoding() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        let json: Data = Data(sampleJSON.utf8)
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase  // convert thingspeak json keys_like_this to keysLikeThis
        decoder.dateDecodingStrategy = .iso8601 // convert iso 8601 date string to date object
        do {
            let data: ThingSpeakChannelData = try decoder.decode(ThingSpeakChannelData.self, from: json)
            print("Succeded to decode JSON")
        } catch {
            print("Failed to decode JSON")
        }        
        
    }

}
