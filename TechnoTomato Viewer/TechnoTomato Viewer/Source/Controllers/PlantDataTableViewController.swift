//
//  PlantDataTableTableViewController.swift
//  Techno Tomato Manager
//
//  Created by DoodleBytes Development on 7/22/19.
//  Copyright © 2019 DoodleBytes Development. All rights reserved.
//

import UIKit

class PlantDataTableViewController: UITableViewController {
    // Using the read api keys for my channels since I don't care if people access the data from my
    // TechnoTomato channels
    var zones: [TechnoTomatoChannel] = [
        TechnoTomatoChannel(key: "7NRS3I3AOW6BU1IB", channelID: 772438, zone: 0),
        TechnoTomatoChannel(key: "93HH13ADEOV3C8G5", channelID: 772821, zone: 1),
        TechnoTomatoChannel(key: "92HNAKFQ3J3NGGIF", channelID: 772824, zone: 2)
    ]
    
    func getPlant( at indexPath: IndexPath ) -> TechnoTomatoPlant {
        let zone: TechnoTomatoChannel = zones[indexPath.section]
        return zone.plants[indexPath.row]
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        for zone in zones {
            zone.updateHandler = {
                [weak self] channel in
                
                self?.updateTable()
            }
            zone.update()
        }
    }

    func updateTable() {
        DispatchQueue.main.async {
            [weak self] in 
            self?.tableView?.reloadData()
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return zones.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return zones[section].count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: k_plant_view_cell_id, for: indexPath)
        if let cell = cell as? PlantTableViewCell {
            let plant: TechnoTomatoPlant = getPlant(at: indexPath)
            plant.indexPath = indexPath
            cell.updateViews(for: plant)
        }

        return cell
    }
    

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        if let controller = segue.destination as? PlantDefaultsViewController, 
            let indexPath: IndexPath = self.tableView.indexPathForSelectedRow {
            
            controller.defaultsKey = "\(indexPath)"
            controller.plant = getPlant(at: indexPath)
        }
    }
    
    
    @IBAction func unwindToMainTable(segue: UIStoryboardSegue) {}

}
