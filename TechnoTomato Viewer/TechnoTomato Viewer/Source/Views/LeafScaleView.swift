//
//  LeafScaleView.swift
//  Techno Tomato Manager
//
//  Created by DoodleBytes Development on 7/22/19.
//  Copyright © 2019 DoodleBytes Development. All rights reserved.
//

import UIKit

class LeafScaleView: TechnoTomatoDataView {

    override func draw(_ rect: CGRect) {
        drawBackground(rect)
        
        guard let plant = self.plant else { return }
        let H: CGFloat = rect.size.height
        let scale: CGFloat = plant.sensorScale(for: rect) // pixels per unit of temperature
        let minSensor: CGFloat = plant.minDisplayedSensorReading
        let maxSensor: CGFloat = plant.maxDisplayedSensorReading
        let warningSensor: CGFloat = plant.warningDisplayedSensorReading
        
        var dy: CGFloat = H - ((maxSensor - minSensor) * scale)
        let maxSensorLabel: NSString = NSString(string: "\(Int(maxSensor))")
        maxSensorLabel.draw(at: CGPoint(x: 10, y: dy), withAttributes: scaleAttributes)
        
        dy = H - 14
        let minSensorLabel: NSString = NSString(string: "\(Int(minSensor))")
        minSensorLabel.draw(at: CGPoint(x: 10, y: dy), withAttributes: scaleAttributes)
        
        dy = H - ((warningSensor - minSensor) * scale) - 7
        let warningSensorLabel: NSString = NSString(string: "\(Int(warningSensor))")
        warningSensorLabel.draw(at: CGPoint(x: 10, y: dy), withAttributes: scaleAttributes)
    }

}
