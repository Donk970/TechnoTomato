//
//  SprayCycleDataPlotter.swift
//  TechnoTomato Viewer
//
//  Created by DoodleBytes Development on 7/21/19.
//  Copyright © 2019 DoodleBytes Development. All rights reserved.
//
import UIKit

class SprayCycleDataPlotter: TechnoTomatoDataPlotter {
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
        
        var index: CGFloat = 0
        let path: UIBezierPath = UIBezierPath()
        for entry in plant.entries {
            let c: Int = Int(entry.sprayCycles)
            let dx: CGFloat = index * hs 
            if c > 0 {
                path.move(to: CGPoint(x: dx, y: H))
                path.addLine(to: CGPoint(x: dx, y: H-10))
            }
            index += 1
        }
        strokeColor.setStroke()
        path.lineWidth = lineWidth
        path.stroke()
        
    }
    
}


