//
//  QuickCarbEntryViewController.swift
//  Loop
//
//  Copyright © 2016 LoopKit Authors. All rights reserved.
//

import Foundation
import UIKit
import CarbKit
import HealthKit


final class QuickCarbEntryViewController: UITableViewController, IdentifiableClass {
    var defaultAbsorptionTimes : CarbStore.DefaultAbsorptionTimes? = nil
    private var internalCarbs : Int = 0
    @IBOutlet weak var glucoseCell: UITableViewCell!
    
    @IBOutlet weak var carbOnBoardLabel: UILabel!
    @IBOutlet weak var carbEntryLabel: UILabel!
    
    @IBOutlet weak var absorptionCell: UITableViewCell!
    @IBOutlet weak var noteTextField: UITextField!
    
    @IBOutlet weak var saveButton: UIButton!
    
    var carbStore: CarbStore?
    var mealInformation: LoopDataManager.MealInformation?
    
    // private var absorptionTime : Int = 180
    var carbs : CarbEntry? = nil
    var glucose : HKQuantity? = nil
    private var internalGlucose : Int = 0
    let foodType = "quickCarbs"
    var carbWarning : Double = 100.0

    var carbsOnBoard : Double = 0.0
    var lastCarbEntry : CarbEntry? = nil
    var totalMealCarbs : Int? = nil
    var mealStart : Date? = nil
    
    var shouldShowAbsorption : Bool = false  // Allow to chose aborption times
    
    var shouldShowGlucose : Bool = false
    var initialGlucose : Int? = nil
    private var glucoseIsModified : Bool = false
    
    var saved : Bool = false
    
    var automatedBolusEnabled : Bool = false
    
    var noteEntered : String = ""
    
    public var preferredGlucoseUnit: HKUnit = HKUnit.milligramsPerDeciliter()
    public var preferredUnit: HKUnit = HKUnit.gram()

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        var rval:CGFloat = 30
        switch indexPath.row {
        case 0: rval = 80  // info
        case 1: rval = 100 // entry
        case 2: if self.shouldShowAbsorption { rval = 60 } else { rval = 0 }  // absorption
        case 3: if self.shouldShowGlucose { rval = 60 } else { rval = 0 }  // glucose
        case 4: rval = 44  // save

        default: rval = 30
        }
        return rval
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.carbs = nil
        self.glucose = nil
        self.saved = false
        
        self.internalCarbs = 0
        
        self.internalGlucose = 0
        self.glucoseIsModified = false
        if self.initialGlucose != nil {
            self.internalGlucose = self.initialGlucose!
            glucoseTextField.text = "\(self.internalGlucose)"
        } else {
            glucoseTextField.text = ""
        }
        if self.carbsOnBoard >= 0 {
            let value = Int(self.carbsOnBoard)
            self.carbOnBoardLabel.text = "Carbs on board: \(value) g"
        } else {
            self.carbOnBoardLabel.text = "Carbs on board: unknown"
        }
        /*
        if let carb = self.lastCarbEntry {
            let amount = Int(carb.quantity.doubleValue(for: preferredUnit))
            let formatter = DateFormatter()
            formatter.dateStyle = .none
            formatter.timeStyle = .short
            let dateStr = formatter.string(from: carb.startDate)
            self.carbEntryLabel.text = "Last carb entry: \(amount) g @\(dateStr)"
        } else {
            self.carbEntryLabel.text = "No carbs in the last 3 hours."
        }
        */
        if let mealStart = mealStart, let carbs = self.totalMealCarbs {
            let formatter = DateFormatter()
            formatter.dateStyle = .none
            formatter.timeStyle = .short
            let dateStr = formatter.string(from: mealStart)
            self.carbEntryLabel.text = "Meal carbs: \(carbs) g since \(dateStr)"
            self.carbOnBoardLabel.text = "! CAREFUL TO NOT ENTER CARBS AGAIN IF BOLUS FAILED !"
            self.carbOnBoardLabel.textColor = UIColor.red
            self.internalCarbs = 0
        } else {
            if self.carbsOnBoard >= 0 {
                let value = Int(self.carbsOnBoard)
                self.carbOnBoardLabel.text = "Carbs on board: \(value) g"
            } else {
                self.carbOnBoardLabel.text = "Carbs on board: unknown"
            }
            self.carbEntryLabel.text = "No meal in progress."
        }

        if !self.shouldShowGlucose {
            glucoseCell.isHidden = true
            // todo set height
        }
        updateCarbLabel()
        
        if self.automatedBolusEnabled {
            self.saveButton.setTitle("Save and automatic Bolus", for: .normal)
        } else {
            self.saveButton.setTitle("Save and go to Bolus", for: .normal)

        }
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        AnalyticsManager.shared.didDisplayQuickCarbScreen()
    }
    
    @IBOutlet weak var glucoseTextField: UITextField!
    
    @IBAction func decrementGlucoseButton(_ sender: Any) {
        if self.internalGlucose == 0 {
            self.internalGlucose = 100
        } else {
            self.internalGlucose = max(0, self.internalGlucose - 5)
        }
        self.glucoseIsModified = true
        updateGlucoseLabel()
    }
   
    @IBAction func incrementGlucoseButton(_ sender: Any) {
        if self.internalGlucose == 0 {
            self.internalGlucose = 100
        } else {
            self.internalGlucose = max(0, self.internalGlucose + 5)
            updateGlucoseLabel()
        }
        self.glucoseIsModified = true
    }
    private func updateGlucoseLabel() {
        glucoseTextField.text = "\(self.internalGlucose)"
        
    }
    
    @IBOutlet weak var absorptionTimeControl: UISegmentedControl!
    
    private func updateCarbLabel() {
        carbLabel.text = "\(self.internalCarbs) g"
    }
    @IBOutlet weak var carbLabel: UILabel!
    
    @IBAction func decrementButton(_ sender: Any) {
        self.internalCarbs = max(0, self.internalCarbs - 5)
        updateCarbLabel()
    }
    
    @IBAction func incrementButton(_ sender: Any) {
        self.internalCarbs = self.internalCarbs + 5
        updateCarbLabel()
    }
    
    @IBAction func saveButton(_ sender: Any) {
        if let mealCarbs = totalMealCarbs, internalCarbs > 0 {
            let futureCarbs = mealCarbs + internalCarbs
            
            guard futureCarbs <= Int(carbWarning) else {
                let alert = UIAlertController(title: "Exceeds Usual Carbs", message: "The carb amount of \(internalCarbs) g together with previously entered carbs of \(mealCarbs) g is higher than the usual amount of \(carbWarning) g. If you are sure that this meal is in total \(futureCarbs) re-enter the amount of \(internalCarbs) g to confirm.", preferredStyle: .alert)
                
                alert.addTextField { (textField) in
                    textField.text = ""
                    textField.keyboardType = UIKeyboardType.decimalPad
                    textField.autocorrectionType = UITextAutocorrectionType.no
                }
                
                alert.addAction(UIAlertAction(title: "Confirm Carbs", style: .default, handler: { [weak alert] (_) in
                    let wanted = "\(self.internalCarbs)"
                    let result = alert?.textFields![0].text
                    if result != nil && result! == wanted {
                        self.setCarbsAndClose()
                    } else {
                        self.presentAlertController(withTitle: NSLocalizedString("Exceeds Usual Carbs", comment: "The title of the alert describing a carbs validation error"), message: String(format: NSLocalizedString("The Validation failed (wanted \(wanted), entered \(result!))", comment: "Body of the alert describing a carb validation error. (1: The localized carb value)")))
                        return
                    }
                }))
                
                alert.addAction(UIAlertAction(title: "Back", style: .default, handler: nil))
                
                self.present(alert, animated: true, completion: nil)
                
                return
            }
        }
        
        self.setCarbsAndClose()
    }
    
    func setCarbsAndClose() {

        if self.internalCarbs > 0 {
            let quantity = HKQuantity(unit: HKUnit.gram(), doubleValue: Double(self.internalCarbs))
                let absorptionTime = AbsorptionSpeed.normal.seconds
                self.carbs = NewCarbEntry(quantity: quantity, startDate: Date(), foodType: self.foodType,
                                          absorptionTime: absorptionTime)
        }
        
        if self.internalGlucose > 0 && glucoseIsModified {
            self.glucose = HKQuantity(unit: preferredGlucoseUnit, doubleValue: Double(self.internalGlucose))
        }
        
        if let text = self.noteTextField.text {
            self.noteEntered = text
        }
        self.saved = true
        AnalyticsManager.shared.didAddCarbsFromQuickCarbs(self.internalCarbs, self.internalGlucose, self.noteEntered)
        self.performSegue(withIdentifier: "close", sender: nil)
    }
    
}
