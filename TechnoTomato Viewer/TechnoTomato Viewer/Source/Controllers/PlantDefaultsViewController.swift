//
//  PlantDefaultsViewController.swift
//  Techno Tomato Manager
//
//  Created by DoodleBytes Development on 7/23/19.
//  Copyright © 2019 DoodleBytes Development. All rights reserved.
//

import UIKit

let k_unwind_to_table_segue: String = "unwindToMainTable"


let k_maxTemperatureField_key: String = "max_displayed_temp"
let k_minTemperatureField_key: String = "min_displayed_temp"
let k_warningTemperatureField_key: String = "warning_displayed_temp"
let k_maxLeafSensorReadingField_key: String = "max_sensor_reading"
let k_minLeafSensorReadingField_key: String = "min_sensor_reading"
let k_warningLeafSensorReadingField_key: String = "warning_sensor_reading"

class PlantDefaultsViewController: UIViewController {
    var defaultsKey: String = ""
    var plant: TechnoTomatoPlant?
    
    @IBOutlet weak var maxTemperatureField: UITextField!
    @IBOutlet weak var minTemperatureField: UITextField!
    @IBOutlet weak var warningTemperatureField: UITextField!
    
    @IBOutlet weak var maxLeafSensorReadingField: UITextField!
    @IBOutlet weak var minLeafSensorReadingField: UITextField!
    @IBOutlet weak var warningLeafSensorReadingField: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()

        maxTemperatureField.addDoneToToolbar()
        minTemperatureField.addDoneToToolbar()
        warningTemperatureField.addDoneToToolbar()
        maxLeafSensorReadingField.addDoneToToolbar()
        minLeafSensorReadingField.addDoneToToolbar()
        warningLeafSensorReadingField.addDoneToToolbar()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        loadDefaults()
    }
    
    @IBAction func cancelDefaultsChange(_ button: UIButton) {
        self.performSegue(withIdentifier: k_unwind_to_table_segue, sender: self)
    }
    
    @IBAction func saveDefaultsChange(_ button: UIButton) {
        storeDefaults()
        plant?.updateFromDefaults()
        self.performSegue(withIdentifier: k_unwind_to_table_segue, sender: self)
    }
    
    func loadDefaults() {
        let defaults = UserDefaults.standard
        let settings: [String: Any] = defaults.dictionary(forKey: defaultsKey) ?? [:]
        maxTemperatureField.text = "\(settings[k_maxTemperatureField_key] ?? 120)"
        minTemperatureField.text = "\(settings[k_minTemperatureField_key] ?? 50)"
        warningTemperatureField.text = "\(settings[k_warningTemperatureField_key] ?? 90)"
        maxLeafSensorReadingField.text = "\(settings[k_maxLeafSensorReadingField_key] ?? 50)"
        minLeafSensorReadingField.text = "\(settings[k_minLeafSensorReadingField_key] ?? -10)"
        warningLeafSensorReadingField.text = "\(settings[k_warningLeafSensorReadingField_key] ?? 30)"
    }
    
    func storeDefaults() {
        let defaults = UserDefaults.standard
        var settings: [String: Any] = [:]
        settings[k_maxTemperatureField_key] = Int(maxTemperatureField.text ?? "120")
        settings[k_minTemperatureField_key] = Int(minTemperatureField.text ?? "50")
        settings[k_warningTemperatureField_key] = Int(warningTemperatureField.text ?? "90")
        settings[k_maxLeafSensorReadingField_key] = Int(maxLeafSensorReadingField.text ?? "50")
        settings[k_minLeafSensorReadingField_key] = Int(minLeafSensorReadingField.text ?? "-10")
        settings[k_warningLeafSensorReadingField_key] = Int(warningLeafSensorReadingField.text ?? "30")
        defaults.set(settings, forKey: defaultsKey)
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}



extension PlantDefaultsViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
}


extension UITextField {
    func addDoneToToolbar() {     
        let toolbar: UIToolbar = UIToolbar()
        toolbar.barStyle = .default
        toolbar.items = [
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil),
            UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(doneButtonTapped))
        ]
        toolbar.sizeToFit()
        
        self.inputAccessoryView = toolbar
    }
    
    // Default actions:  
    @objc func doneButtonTapped() { self.resignFirstResponder() }
}


/*
 update sensor and temp display limits from defaults
 */
extension TechnoTomatoPlant {
    
    func updateFromDefaults() {
        let defaults = UserDefaults.standard
        let settings: [String: Any] = defaults.dictionary(forKey: defaultsKey) ?? [:]
        maxDisplayedTemperature = (settings[k_maxTemperatureField_key] as? CGFloat) ?? 120
        minDisplayedTemperature = (settings[k_minTemperatureField_key] as? CGFloat) ?? 50
        warningDisplayedTemperature = (settings[k_warningTemperatureField_key] as? CGFloat) ?? 90
        maxDisplayedSensorReading = (settings[k_maxLeafSensorReadingField_key] as? CGFloat) ?? 50
        minDisplayedSensorReading = (settings[k_minLeafSensorReadingField_key] as? CGFloat) ?? -10
        warningDisplayedSensorReading = (settings[k_warningLeafSensorReadingField_key] as? CGFloat) ?? 30
    }
    
}
