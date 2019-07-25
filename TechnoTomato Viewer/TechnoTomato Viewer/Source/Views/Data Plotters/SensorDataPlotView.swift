//
//  Plotter.swift
//  Techno Tomato Manager
//
//  Created by DoodleBytes Development on 7/21/19.
//  Copyright © 2019 DoodleBytes Development. All rights reserved.
//

import UIKit


protocol TechnoTomatoDataPlotter {
    var strokeColor: UIColor {get set}
    var lineWidth: CGFloat {get set}
    
    func drawDataPoints(for plant: TechnoTomatoPlant, in rect: CGRect)
}



let k_air_temp_color: UIColor = UIColor(red: 0.84, green: 0.13, blue: 0.13, alpha: 0.2)
let k_root_temp_color: UIColor = UIColor(red: 0.84, green: 0.13, blue: 0.13, alpha: 0.2)
let k_sensor_color: UIColor = UIColor(red: 0.122, green: 0.42, blue: 0.31, alpha: 1)
let k_spray_color: UIColor = UIColor(red: 0.2, green: 0.6, blue: 1.0, alpha: 0.4)

class SensorDataPlotView: TechnoTomatoDataView {
    
    @IBInspectable var airTempColor: UIColor = k_air_temp_color
    @IBInspectable var rootTempColor: UIColor = k_root_temp_color
    @IBInspectable var sensorColor: UIColor = k_sensor_color
    @IBInspectable var sprayColor: UIColor = k_spray_color
    
    var dataPlotters: [TechnoTomatoDataPlotter] = []

    override func awakeFromNib() {
        super.awakeFromNib()
        
        dataPlotters = [
            SprayCycleDataPlotter(strokeColor: sprayColor, lineWidth: 0.5),
            AirTemperatureDataPlotter(strokeColor: airTempColor, lineWidth: 2),
            RootTemperatureDataPlotter(strokeColor: rootTempColor, lineWidth: 2),
            LeafSensorDataPlotter(strokeColor: sensorColor, lineWidth: 2)
        ]
    }
    
    override func draw(_ rect: CGRect) {
        guard let plant = self.plant else { return }
        drawBackground(rect)
        
        for plotter in dataPlotters {
            plotter.drawDataPoints(for: plant, in: rect)
        }
    }
      
}









