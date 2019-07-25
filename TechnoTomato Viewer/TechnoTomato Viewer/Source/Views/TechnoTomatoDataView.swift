//
//  TechnoTomatoDataView.swift
//  Techno Tomato Manager
//
//  Created by DoodleBytes Development on 7/21/19.
//  Copyright © 2019 DoodleBytes Development. All rights reserved.
//

import UIKit





class TechnoTomatoDataView: UIView {
    weak var plant: TechnoTomatoPlant? = nil
    
    func drawBackground(_ rect: CGRect) {
        if let bg: UIColor = superview?.backgroundColor {
            bg.setFill()
        } else {
            UIColor.white.setFill()
        }
        UIRectFill(rect)
        
        self.backgroundColor?.darkerColor.setStroke()
        self.backgroundColor?.setFill()
        let path = UIBezierPath(roundedRect: rect, cornerRadius: 4)
        path.lineWidth = 2
        path.fill()
        path.stroke()
    }
    
    func updateView( for plant: TechnoTomatoPlant ) {
        self.plant = plant 
        self.setNeedsDisplay()
    }
    
    var horizontalScale: CGFloat {
        guard let plant = self.plant else { return 1 }
        let dt: CGFloat = CGFloat(plant.dt)
        if dt == 0 { return 1 }
        let S: CGFloat = self.frame.size.width
        return S/dt //pixels per second
    }

}




extension TechnoTomatoPlant {
    
    var t0: Date {
        guard let e0: TechnoTomatoPlantEntry = entries.first else { return Date() }
        return e0.time
    }
    
    var dt: TimeInterval {
        guard let e0: TechnoTomatoPlantEntry = entries.first else { return 1.0 }
        guard let en: TechnoTomatoPlantEntry = entries.last else { return 1.0 }
        return en.time.timeIntervalSinceReferenceDate - e0.time.timeIntervalSinceReferenceDate
    }
        
    var temperatureRangeInfo: (min: CGFloat, max: CGFloat, minAirTemp: CGFloat, maxAirTemp: CGFloat, minRootTemp: CGFloat, maxRootTemp: CGFloat) {
        var min: CGFloat = 1000000
        var max: CGFloat = -1000000
        var minAir: CGFloat = 1000000
        var maxAir: CGFloat = -1000000
        var minRoot: CGFloat = 1000000
        var maxRoot: CGFloat = -1000000
        for entry in entries {
            let a = entry.airTempF
            minAir = a < minAir ? a : minAir 
            maxAir = a > maxAir ? a : maxAir 
            min = a < min ? a : min 
            max = a > max ? a : max 
            let r = entry.rootTempF
            minRoot = r < minRoot ? r : minRoot 
            maxRoot = r > maxRoot ? r : maxRoot 
            min = r < min ? r : min 
            max = r > max ? r : max 
        }
        return (min, max, minAir, maxAir, minRoot, maxRoot)
    }
    
    var firstMinorTickOffset: (offset: TimeInterval, m: Int) {
        let date: Date = self.t0
        let components: DateComponents = NSCalendar.current.dateComponents([.hour, .minute, .second, .nanosecond], from: date)
        let m0: Int = components.minute ?? 0
        let s0: Int = components.second ?? 0
        var m1: Int = ((m0/15)*15) + 15 // the first visible 15 minute incriment 
        if m1 >= 60 { m1 = 0 }
        let t1: TimeInterval = TimeInterval(m1 * 60)
        let offset: TimeInterval = t1 - TimeInterval((m0 * 60) + s0) // seconds between the first 15 minute mark and t0
        return (offset, m1)
    }
    
    var firstMajorTickOffset: (offset: TimeInterval, h: Int) {
        let date: Date = self.t0
        let components: DateComponents = NSCalendar.current.dateComponents([.hour, .minute, .second, .nanosecond], from: date)
        let h0: Int = components.hour ?? 0
        let m0: Int = components.minute ?? 0
        let s0: Int = components.second ?? 0
        let h1: Int = h0 + 1 // the first visible 1 hour incriment 
        let t1: TimeInterval = TimeInterval(h1 * 3600)
        let offset: TimeInterval = t1 - TimeInterval((h0 * 3600) + (m0 * 60) + s0) // seconds between the first hour mark and t0
        return (offset, h1)
    }
    
    func tempScale( for rect: CGRect ) -> CGFloat {
        let S: CGSize = rect.size
        let H: CGFloat = S.height
        let min = self.minDisplayedTemperature
        let max = self.maxDisplayedTemperature
        var dt = abs(max - min)
        if dt < 10 { dt = 10 }
        return H/dt // pixels per unit of temperature
    }
    
    func sensorScale( for rect: CGRect ) -> CGFloat {
        let H: CGFloat = rect.size.height
        let min = self.minDisplayedSensorReading
        let max = self.maxDisplayedSensorReading
        var dt = abs(max - min) 
        if dt < 10 { dt = 10 }
        return H/dt // pixels per unit of temperature
    }
    
}




extension UIColor {
    
    var darkerColor: UIColor {
        return darkerColor(addSaturation: 0.05, resultAlpha: -1)
    }
    
    func darkerColor(addSaturation val: CGFloat, resultAlpha alpha: CGFloat) -> UIColor {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        guard getRed(&r, green: &g, blue: &b, alpha: &a) else { return self }
        
        let d: CGFloat = 1 - val 
        return UIColor(red: r*d, green: g*d, blue: b*d, alpha: a)
    }
    
}








let scaleAttributes: [NSAttributedString.Key: Any] = {
    let font = UIFont.systemFont(ofSize: 10)
    let shadow = NSShadow()
    shadow.shadowColor = UIColor.gray
    shadow.shadowBlurRadius = 2
    shadow.shadowOffset = CGSize(width: 1, height: 1)
    
    return [
        .font: font,
        .foregroundColor: UIColor.darkGray,
        .shadow: shadow
    ]
}()
