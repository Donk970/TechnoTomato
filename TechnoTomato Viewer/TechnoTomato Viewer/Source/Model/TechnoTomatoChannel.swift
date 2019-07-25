//
//  ThingSpeakChannelAgregat.swift
//  Techno Tomato Manager
//
//  Created by DoodleBytes Development on 7/21/19.
//  Copyright © 2019 DoodleBytes Development. All rights reserved.
//

import Foundation
import CoreGraphics




struct TechnoTomatoPlantEntry {
    let time: Date
    let airTempC: CGFloat
    var airTempF: CGFloat {
        return (self.airTempC * 9/5) + 32 
    }
    let airHumidity: CGFloat
    let rootTempC: CGFloat
    var rootTempF: CGFloat {
        return (self.rootTempC * 9/5) + 32 
    }
    let rootHumidity: CGFloat
    let leafValue: CGFloat
    let sprayCycles: CGFloat
}


class TechnoTomatoPlant {
    var entries: [TechnoTomatoPlantEntry] = []
    var indexPath: IndexPath = IndexPath(row: 0, section: 0)
    var zone: Int {
        return indexPath.section + 1
    }
    var plant: Int {
        return indexPath.row + 1
    }
    var defaultsKey: String {
        return "\(indexPath)"
    }

    var minDisplayedTemperature: CGFloat = 50
    var maxDisplayedTemperature: CGFloat = 100
    var warningDisplayedTemperature: CGFloat = 90
    
    var minDisplayedSensorReading: CGFloat = -10
    var maxDisplayedSensorReading: CGFloat = 50
    var warningDisplayedSensorReading: CGFloat = 30
}


/**
 ## TechnoTomatoChannel
 
 This is the UI model layer that reorganizes the raw thingspeak channel feed into
 an array of TechnoTomatoPlant objects that provide data in a form that is easy to
 plot in the UI.
 */
class TechnoTomatoChannel {
    let channel: ThingSpeakChannel
    var updateInterval: TimeInterval = 60; // default to a one minute interval
    
    //we know that we can only have a maximum of 3 plants in our channel
    let plants: [TechnoTomatoPlant] = [TechnoTomatoPlant(), TechnoTomatoPlant(), TechnoTomatoPlant()]
    var count: Int { return plants.count }
    let zone: Int 
    
    init( key: String, channelID: Int, zone: Int ) {
        self.channel = ThingSpeakChannel(key: key, channelID: channelID)
        self.zone = zone
        plants[0].indexPath = IndexPath(row: 0, section: zone)
        plants[0].updateFromDefaults()
        
        plants[1].indexPath = IndexPath(row: 1, section: zone)
        plants[1].updateFromDefaults()
        
        plants[2].indexPath = IndexPath(row: 2, section: zone)
        plants[2].updateFromDefaults()
    }
    
    var updateHandler: ((TechnoTomatoChannel) -> Void)?
    func update( delay: TimeInterval = 1 ) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: {
            [weak self] in
            guard let strongSelf = self else { 
                // if this instance has been dealloced just bail out
                return 
            }
            
            strongSelf.channel.updateData(count: 240, completion: {
                [weak self] channel in
                guard let strongSelf = self else { 
                    // if this instance has been dealloced just bail out
                    return 
                }
                
                // handle new set of data points for this channel
                if let channelData = channel.data {
                    let entries: [[TechnoTomatoPlantEntry]] = channelData.technoTomatoEntries
                    if entries.count > 0 && strongSelf.plants.count > 0 { strongSelf.plants[0].entries = entries[0] }            
                    if entries.count > 1 && strongSelf.plants.count > 1 { strongSelf.plants[1].entries = entries[1] }
                    if entries.count > 2 && strongSelf.plants.count > 2 { strongSelf.plants[2].entries = entries[2] }
                }
                
                // trigger a new update with a delay
                strongSelf.updateHandler?(strongSelf)
                strongSelf.update(delay: strongSelf.updateInterval)
            }) 
        })     
    }
}


extension ThingSpeakChannelData {
    var technoTomatoEntries: [[TechnoTomatoPlantEntry]] {
        //feeds is a time series of Feed entries
        var plantEntries: [[TechnoTomatoPlantEntry]] = [[TechnoTomatoPlantEntry](), [TechnoTomatoPlantEntry](), [TechnoTomatoPlantEntry]()]
        for feed in feeds {
            let entries: [TechnoTomatoPlantEntry] = feed.technoTomatoEntries
            if entries.count > 0 { plantEntries[0].append(entries[0]) }            
            if entries.count > 1 { plantEntries[1].append(entries[1]) }
            if entries.count > 2 { plantEntries[2].append(entries[2]) }
        }
        return plantEntries
    }
}


extension Feed {
    // this is a single entry in the channel feed representing 
    // a time stamp and all the channel fields
    
    /*
     Encode our knowlege of what each field holds into a set of 
     TechnoTomatoPlantEntry structs
     */
    var technoTomatoEntries: [TechnoTomatoPlantEntry] {
        let airTemp: Float = Float(self.field7 ?? "0.0") ?? 0.0
        let rootTemp: Float = Float(self.field8 ?? "0.0") ?? 0.0
        
        var entries: [TechnoTomatoPlantEntry] = []
        
        if let f1 = field1, let l = Float(f1), let f2 = field2, let s = Float(f2) {
            let e: TechnoTomatoPlantEntry = TechnoTomatoPlantEntry(time: createdAt, 
                                                                    airTempC: CGFloat(airTemp), 
                                                                    airHumidity: 30.0, 
                                                                    rootTempC: CGFloat(rootTemp), 
                                                                    rootHumidity: 30.0, 
                                                                    leafValue: CGFloat(l), 
                                                                    sprayCycles: CGFloat(s))
            
            entries.append(e)
        }
        
        if let f3 = field3, let l = Float(f3), let f4 = field4, let s = Float(f4) {
            let e: TechnoTomatoPlantEntry = TechnoTomatoPlantEntry(time: createdAt, 
                                                                    airTempC: CGFloat(airTemp), 
                                                                    airHumidity: 30.0, 
                                                                    rootTempC: CGFloat(rootTemp), 
                                                                    rootHumidity: 30.0, 
                                                                    leafValue: CGFloat(l), 
                                                                    sprayCycles: CGFloat(s))
            
            entries.append(e)
        }
        
        if let f5 = field5, let l = Float(f5), let f6 = field6, let s = Float(f6) {
            let e: TechnoTomatoPlantEntry = TechnoTomatoPlantEntry(time: createdAt, 
                                                                    airTempC: CGFloat(airTemp), 
                                                                    airHumidity: 30.0, 
                                                                    rootTempC: CGFloat(rootTemp), 
                                                                    rootHumidity: 30.0, 
                                                                    leafValue: CGFloat(l), 
                                                                    sprayCycles: CGFloat(s))
            
            entries.append(e)
        }
        
        
        return entries
    }
}


extension IndexPath {
    
    var defaultsKey: String {
        return "\(self)"
    }
    
}
