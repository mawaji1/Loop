//
//  BolusViewController+LoopDataManager.swift
//  Loop
//
//  Copyright © 2017 LoopKit Authors. All rights reserved.
//

import UIKit
import HealthKit


extension BolusViewController {
    func configureWithLoopManager(_ manager: LoopDataManager, recommendation: BolusRecommendation?, glucoseUnit: HKUnit, expertMode: Bool) {
        manager.getLoopState { (manager, state) in
            let maximumBolus = manager.settings.maximumBolus
            let maxInsulinOnBoard = manager.settings.maximumInsulinOnBoard
            let activeCarbohydrates = state.carbsOnBoard?.quantity.doubleValue(for: .gram())
            let bolusRecommendation: BolusRecommendation?

            if let recommendation = recommendation {
                bolusRecommendation = recommendation
            } else {
                bolusRecommendation = try? state.recommendBolus()
            }
            
            let iob = state.insulinOnBoard

                DispatchQueue.main.async {
                    if let maxBolus = maximumBolus {
                        self.maxBolus = maxBolus
                    }
                    self.maximumInsulinOnBoard = maxInsulinOnBoard

                    self.glucoseUnit = glucoseUnit
                    self.activeInsulin = iob?.value
                    self.activeCarbohydrates = activeCarbohydrates
                    self.bolusRecommendation = bolusRecommendation
                    
                    self.expertMode = expertMode
                }
            
        }
    }
}
