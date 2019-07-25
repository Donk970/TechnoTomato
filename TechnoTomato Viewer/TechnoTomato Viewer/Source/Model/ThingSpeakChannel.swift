//
//  ThingSpeakChannel.swift
//  Techno Tomato Manager
//
//  Created by DoodleBytes Development on 7/21/19.
//  Copyright © 2019 DoodleBytes Development. All rights reserved.
//

import Foundation

/**
 ## ThingSpeakChannel
 
 This is a very generic class that takes a channel id and a key in its initializer
 and then fetches the channel feed from the thingspeak api when told to.  When json
 data is received it is decoded into a ThingSpeakChannelData object and a completion
 closure is called to finish.
*/
class ThingSpeakChannel {
    let channelID: Int
    let key: String
    var count: Int = 1
    
    init( key: String, channelID: Int ) {
        self.channelID = channelID
        self.key = key 
    }
    
    var url: URL? {
        let str: String = "https://api.thingspeak.com/channels/\(channelID)/feeds.json?api_key=\(key)&results=\(count)"
        return URL(string: str)
    }
    
    func updateData( count: Int, completion: ((ThingSpeakChannel) -> Void)? ) {
        self.count = count 
        guard let url: URL = self.url else { return }
        let task: URLSessionDataTask = URLSession.shared.dataTask(with: url) { 
            (data: Data?, response: URLResponse?, error: Error?) in
            
            if let error: Error = error {
                // handle the error - not yet sure what I want to do with this
                return 
            }
            
            guard let response: URLResponse = response else {
                // handle no response as an error
                return
            }
            
            guard let data: Data = data else {
                // handle no data as an error
                return
            }
            
            self.json = data
            completion?(self)
        }
        task.resume()
    }
    
    var data: ThingSpeakChannelData?
    var json: Data? = nil {
        didSet {
            guard let json = self.json else { return }
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase  // convert thingspeak json keys_like_this to keysLikeThis
            decoder.dateDecodingStrategy = .iso8601 // convert iso 8601 date string to date object
            do {
                data = try decoder.decode(ThingSpeakChannelData.self, from: json)
            } catch {
                data = nil
                print("Failed to decode JSON")
            }        
        }
        
    }
}


struct ThingSpeakChannelData: Decodable {
    let channel: Channel 
    let feeds: [Feed]
}

struct Channel: Decodable {
    let id: Int 
    let lastEntryId: Int 
    let name: String 
    let description: String 
    let latitude: String 
    let longitude: String 
    let field1: String? 
    let field2: String? 
    let field3: String?  
    let field4: String? 
    let field5: String? 
    let field6: String? 
    let field7: String? 
    let field8: String?
    let createdAt: Date 
    let updatedAt: Date 
}

struct Feed: Decodable {
    let entryId: Int 
    let createdAt: Date
    let field1: String?
    let field2: String?
    let field3: String?
    let field4: String?
    let field5: String?
    let field6: String?
    let field7: String?
    let field8: String?
}




extension Feed: CustomStringConvertible {
    var description: String {
        var desc: String = "<Feed: "
        var s: String = ""
        let m = Mirror(reflecting: self)
        for (name, value) in m.children {
            guard let name = name else { continue }
            var v: String = ""
            if let i: Int = value as? Int { v = String(i) }
            else if let s: String = value as? String { v = s }
            else if let d: Date = value as? Date { v = d.description }
            desc += s + name + ": " + v
            s = ", "
        }
        return desc
    }
}

