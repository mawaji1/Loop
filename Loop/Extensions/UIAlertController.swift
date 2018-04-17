//
//  UIAlertController.swift
//  Loop
//
//  Created by Nate Racklyeft on 7/17/16.
//  Copyright © 2016 Nathan Racklyeft. All rights reserved.
//

import UIKit


extension UIAlertController {
    /**
     Initializes an ActionSheet-styled controller for selecting a workout duration
     
     - parameter handler: A closure to execute when the sheet is dismissed after selection. The closure has a single argument:
        - endDate: The date at which the user selected the workout to end
     */
    convenience init(workoutDurationSelectionHandler handler: @escaping (_ endDate: Date, _ disconnect: Bool) -> Void) {
        self.init(
            title: NSLocalizedString("Use Workout Glucose Targets", comment: "The title of the alert controller used to select a duration for workout targets"),
            message: nil,
            preferredStyle: .actionSheet
        )

        let formatter = DateComponentsFormatter()
        formatter.allowsFractionalUnits = false
        formatter.unitsStyle = .full

        for interval in [1, 2, 4].map({ TimeInterval(hours: $0) }) {
            let duration = NSLocalizedString("🏃⚽ For %1$@", comment: "The format string used to describe a finite workout targets duration")

            addAction(UIAlertAction(title: String(format: duration, formatter.string(from: interval)!), style: .default) { _ in
                handler(Date(timeIntervalSinceNow: interval), false)
            })
        }
        

//        let distantFuture = NSLocalizedString("Indefinitely", comment: "The title of a target alert action specifying an indefinitely long workout targets duration")
//        addAction(UIAlertAction(title: distantFuture, style: .default) { _ in
//            handler(Date.distantFuture)
//        })
        
        let action = UIAlertAction(title: String(format: "🏊 Disconnect Pump"), style: .default) { _ in
            handler(Date(timeIntervalSinceNow: -1), true)
        }
        addAction(action)
        
        let cancel = NSLocalizedString("Cancel", comment: "The title of the cancel action in an action sheet")
        addAction(UIAlertAction(title: cancel, style: .cancel, handler: nil))
    }
}
