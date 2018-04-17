//
//  CarbEntry.swift
//  Loop
//
//  Copyright © 2017 LoopKit Authors. All rights reserved.
//

import Foundation
import CarbKit
import HealthKit

extension CarbEntry {
    func foodPicks() -> FoodPicks {
        var picks = FoodPicks()
        
        if  let foodType = self.foodType {
            picks = FoodPicks(fromJSON: foodType)
        }
        if picks.last == nil {
            // create generic entry if foodType did not parse
            let value = quantity.doubleValue(for: HKUnit.gram())
            // TODO(Erik) This should take selected absorption time into account
            let foodItem = FoodItem(carbRatio: 1.0, portionSize: value, absorption: .normal, title: "CarbEntry")
            let foodPick = FoodPick(item: foodItem, ratio: 1, date: startDate)
            picks.append(foodPick)
        }
        return picks
    }
}
