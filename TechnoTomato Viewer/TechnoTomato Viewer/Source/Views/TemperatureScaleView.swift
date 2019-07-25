//
//  TemperatureScaleView.swift
//  Techno Tomato Manager
//
//  Created by DoodleBytes Development on 7/22/19.
//  Copyright © 2019 DoodleBytes Development. All rights reserved.
//

import UIKit

class TemperatureScaleView: TechnoTomatoDataView {

    override func draw(_ rect: CGRect) {
        drawBackground(rect)
        
        guard let plant = self.plant else { return }
        let H: CGFloat = rect.size.height
        let scale: CGFloat = plant.tempScale(for: rect) // pixels per unit of temperature
        let minTemp: CGFloat = plant.minDisplayedTemperature
        let maxTemp: CGFloat = plant.maxDisplayedTemperature
        let warningTemp: CGFloat = plant.warningDisplayedTemperature
        let lastRootTemp: CGFloat = plant.entries.last?.rootTempF ?? warningTemp
        let lastAirTemp: CGFloat = plant.entries.last?.airTempF ?? warningTemp
        
        var dy: CGFloat = H - ((maxTemp - minTemp) * scale)
        let maxTempLabel: NSString = NSString(string: "\(Int(maxTemp))℉")
        maxTempLabel.draw(at: CGPoint(x: 0, y: dy), withAttributes: scaleAttributes)
        
        dy = H - 14
        let minTempLabel: NSString = NSString(string: "\(Int(minTemp))℉")
        minTempLabel.draw(at: CGPoint(x: 0, y: dy), withAttributes: scaleAttributes)
        
        dy = H - ((lastAirTemp - minTemp) * scale) - 7
        let lastAirTempLabel: NSString = NSString(string: "\(Int(lastAirTemp))℉")
        lastAirTempLabel.draw(at: CGPoint(x: 0, y: dy), withAttributes: scaleAttributes)
        
        var rdy: CGFloat = H - ((lastRootTemp - minTemp) * scale) - 7
        if abs(rdy - dy) > 5 {
            let lastRootTempLabel: NSString = NSString(string: "\(Int(lastRootTemp))℉")
            lastRootTempLabel.draw(at: CGPoint(x: 0, y: rdy), withAttributes: scaleAttributes)
        }
    }

}
