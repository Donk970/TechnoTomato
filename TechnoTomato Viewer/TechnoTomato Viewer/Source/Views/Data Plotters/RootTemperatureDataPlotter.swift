//
//  RootTemperatureDataPlotter.swift
//  TechnoTomato Viewer
//
//  Created by DoodleBytes Development on 7/21/19.
//  Copyright © 2019 DoodleBytes Development. All rights reserved.
//
import UIKit

class RootTemperatureDataPlotter: TechnoTomatoDataPlotter {
    var strokeColor: UIColor
    var lineWidth: CGFloat
    
    init(strokeColor: UIColor, lineWidth: CGFloat) {
        self.strokeColor = strokeColor
        self.lineWidth = lineWidth
    }
    
    func drawDataPoints(for plant: TechnoTomatoPlant, in rect: CGRect) {
        let W: CGFloat = rect.size.width
        let H: CGFloat = rect.size.height
        let C: CGFloat = CGFloat(plant.entries.count)
        let hs: CGFloat = W/C 
        let vs: CGFloat = plant.tempScale(for: rect)
        let minTemp: CGFloat = plant.minDisplayedTemperature
        
        var index: CGFloat = 0
        var first: Bool = true
        let path: UIBezierPath = UIBezierPath()
        for entry in plant.entries {
            let dx: CGFloat = index * hs 
            let dy: CGFloat = H - ((entry.rootTempF - minTemp) * vs)
            first ? path.move(to: CGPoint(x: dx, y: dy)) : path.addLine(to: CGPoint(x: dx, y: dy))
            index += 1
            first = false
        }
        strokeColor.setStroke()
        path.lineWidth = lineWidth
        path.stroke()
        
    }
    
}


