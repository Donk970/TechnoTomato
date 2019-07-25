//
//  PlantTableViewCell.swift
//  Techno Tomato Manager
//
//  Created by DoodleBytes Development on 7/22/19.
//  Copyright © 2019 DoodleBytes Development. All rights reserved.
//

import UIKit


let k_plant_view_cell_id: String = "plantDataViewCell"

class PlantTableViewCell: UITableViewCell {
    @IBOutlet weak var titleLabel: UILabel?
    @IBOutlet var dataViews: [TechnoTomatoDataView] = []
    
    weak var plant: TechnoTomatoPlant? = nil

    func updateViews( for plant: TechnoTomatoPlant ) {
        self.plant = plant         
        titleLabel?.text = "Zone: \(plant.zone)  Plant: \(plant.plant)"
        for view in dataViews {
            view.updateView(for: plant)
        }
        self.contentView.setNeedsDisplay()
    }
    
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
