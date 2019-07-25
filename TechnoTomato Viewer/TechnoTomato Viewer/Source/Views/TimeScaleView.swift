//
//  TimeScaleView.swift
//  Techno Tomato Manager
//
//  Created by DoodleBytes Development on 7/22/19.
//  Copyright © 2019 DoodleBytes Development. All rights reserved.
//

import UIKit

class TimeScaleView: TechnoTomatoDataView {
    var firstIncriment: TimeInterval = 0
    
    
    override func updateView( for plant: TechnoTomatoPlant ) {
        super.updateView(for: plant)
    }
    
    override func draw(_ rect: CGRect) {
        drawBackground(rect)
        
        let W: CGFloat = rect.size.width
        let H: CGFloat = rect.size.height
        let h: CGFloat = H - 15
        let scale: CGFloat = self.horizontalScale
        
        // draw the minor ticks
        let minorTickInfo: (dt: TimeInterval, m: Int) = plant?.firstMinorTickOffset ?? (0, 0)
        var minorTickOffset: CGFloat = CGFloat(minorTickInfo.dt)
        var dx: CGFloat = minorTickOffset * scale 
        let minorPath: UIBezierPath = UIBezierPath()
        while dx < W {
            let p0: CGPoint = CGPoint(x: dx, y: 0)
            let p1: CGPoint = CGPoint(x: dx, y: 5)
            minorPath.move(to: p0)
            minorPath.addLine(to: p1)           
            minorTickOffset += 900
            dx = minorTickOffset * scale 
        }
        UIColor.gray.setStroke()
        minorPath.stroke()
        
        // draw the major ticks and labels
        let majorTickInfo: (dt: TimeInterval, h: Int) = plant?.firstMajorTickOffset ?? (0, 0)
        var hour: Int = majorTickInfo.h
        var majorTickOffset: CGFloat = CGFloat(majorTickInfo.dt)
        var DX: CGFloat = majorTickOffset * scale 
        let majorPath: UIBezierPath = UIBezierPath()
        while DX < W {
            let P0: CGPoint = CGPoint(x: DX, y: 0)
            let P1: CGPoint = CGPoint(x: DX, y: 10)
            majorPath.move(to: P0)
            majorPath.addLine(to: P1)
            let tLabel: NSString = NSString(string: "\(hour):00")
            tLabel.draw(at: CGPoint(x: (DX - 15), y: h), withAttributes: scaleAttributes)
            majorTickOffset += 3600
            DX = majorTickOffset * scale 
            hour += 1
            if hour > 24 { hour = 0 }
        }
        UIColor.gray.setStroke()
        majorPath.stroke()
    }

}



