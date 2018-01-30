//
//  DoseStore.swift
//  Loop
//
//  Created by Nate Racklyeft on 7/31/16.
//  Copyright © 2016 Nathan Racklyeft. All rights reserved.
//

import InsulinKit
import MinimedKit
import NightscoutUploadKit

public enum FakeEventTypes: UInt8 {
    case note = 0xfe  // Must not exist in MinimedKit.PumpEventType!
    case siteChange = 0xfd
    case insulinChange = 0xfc
    case bgReceived = 0xfb
}

// Bridges support for MinimedKit data types
extension LoopDataManager {
    /**
     Adds and persists new pump events.
     */
    func addPumpEvents(_ pumpEvents: [TimestampedHistoryEvent], from model: MinimedKit.PumpModel, completion: @escaping (_ error: DoseStore.DoseStoreError?) -> Void) {
        var events: [NewPumpEvent] = []
        var lastTempBasalAmount: DoseEntry?
        var isRewound = false
        var title: String

        for event in pumpEvents {
            var dose: DoseEntry?
            var eventType: InsulinKit.PumpEventType?

            switch event.pumpEvent {
            case let bolus as BolusNormalPumpEvent:
                // For entries in-progress, use the programmed amount
                let units = event.isMutable() ? bolus.programmed : bolus.amount

                dose = DoseEntry(type: .bolus, startDate: event.date, endDate: event.date.addingTimeInterval(bolus.duration), value: units, unit: .units)
            case is SuspendPumpEvent:
                dose = DoseEntry(suspendDate: event.date)
            case is ResumePumpEvent:
                dose = DoseEntry(resumeDate: event.date)
            case let temp as TempBasalPumpEvent:
                if case .Absolute = temp.rateType {
                    lastTempBasalAmount = DoseEntry(type: .tempBasal, startDate: event.date, value: temp.rate, unit: .unitsPerHour)
                }
            case let temp as TempBasalDurationPumpEvent:
                if let amount = lastTempBasalAmount, amount.startDate == event.date {
                    dose = DoseEntry(
                        type: .tempBasal,
                        startDate: event.date,
                        endDate: event.date.addingTimeInterval(TimeInterval(minutes: Double(temp.duration))),
                        value: amount.unitsPerHour,
                        unit: .unitsPerHour
                    )
                }
            case let basal as BasalProfileStartPumpEvent:
                dose = DoseEntry(
                    type: .basal,
                    startDate: event.date,
                    // Use the maximum-possible duration for a basal entry; its true duration will be reconciled against other entries.
                    endDate: event.date.addingTimeInterval(.hours(24)),
                    value: basal.scheduleEntry.rate,
                    unit: .unitsPerHour
                )
            case is RewindPumpEvent:
                eventType = .rewind

                /* 
                 No insulin is delivered between the beginning of a rewind until the suggested fixed prime is delivered or cancelled.
 
                 If the fixed prime is cancelled, it is never recorded in history. It is possible to cancel a fixed prime and perform one manually some time later, but basal delivery will have resumed during that period.
                 
                 We take the conservative approach and assume delivery is paused only between the Rewind and the first Prime event.
                 */
                dose = DoseEntry(suspendDate: event.date)
                isRewound = true
            case is PrimePumpEvent:
                eventType = .prime

                if isRewound {
                    isRewound = false
                    dose = DoseEntry(resumeDate: event.date)
                }
            case let alarm as PumpAlarmPumpEvent:
                eventType = .alarm

                if case .noDelivery = alarm.alarmType {
                    dose = DoseEntry(suspendDate: event.date)
                }
                break
            case let alarm as ClearAlarmPumpEvent:
                eventType = .alarmClear

                if case .noDelivery = alarm.alarmType {
                    dose = DoseEntry(resumeDate: event.date)
                }
                break
            default:
                break
            }

            title = String(describing: event.pumpEvent)
            events.append(NewPumpEvent(date: event.date, dose: dose, isMutable: event.isMutable(), raw: event.pumpEvent.rawData, title: title, type: eventType))
        }

        addPumpEvents(events, completion: completion)
    }
    
    // Modifications to handle more logging events from App in Nightscout
    //
    private func addFakeEvent(_ type: FakeEventTypes, _ note: String) {
        UserDefaults.standard.pendingTreatments.append((type: Int(type.rawValue), date: Date(), note: note))
        uploadTreatments()
    }
    
    private func uploadTreatments() {
        var treatments = [NightscoutTreatment]()
        let author = "loop://\(UIDevice.current.name)"
        // TODO(Erik) needs locking
        let pendingTreatments = UserDefaults.standard.pendingTreatments
        UserDefaults.standard.pendingTreatments = []
        
        for rawTreatment in pendingTreatments {
            let date = rawTreatment.date
            let note = rawTreatment.note
            guard let eventType = FakeEventTypes(rawValue: UInt8(rawTreatment.type)) else {
                print("uploadTreatments, invalid eventType", rawTreatment)
                continue
            }
            switch(eventType) {
        
            case .note:
                treatments.append(NoteNightscoutTreatment(timestamp: date, enteredBy: author, notes: note))
            case .insulinChange:
                treatments.append(NightscoutTreatment(timestamp: date, enteredBy: author, notes:  "Automatically added: \(note)", eventType: "Insulin Change"))
            case .siteChange:
                treatments.append(NightscoutTreatment(timestamp: date, enteredBy: author, notes:  "Automatically added: \(note)", eventType: "Site Change"))
            case .bgReceived:
                let parts = note.split(separator: " ", maxSplits: 1)
                let amount = Int(parts[0]) ?? 0
                let comment = String(parts[1])
                let treatment = BGCheckNightscoutTreatment(
                    timestamp: date,
                    enteredBy: author,
                    glucose: amount,
                    glucoseType: .Meter,
                    units: .MGDL,
                    notes: comment
                )
                treatments.append(treatment)
            }
        }

        delegate.loopDataManager(self, uploadTreatments: treatments) { (notUploadedTreatments) in
            if notUploadedTreatments.count > 0 {
                // TODO(Erik): This is a bit messed up - and should probably rather live in the delegate
                for pending in pendingTreatments {
                    UserDefaults.standard.pendingTreatments.append(pending)
                }
            }
        }
    }
    
    public func addNote(_ text: String) {
        print("addNote: ", text)
        addFakeEvent(.note, text)
    }
    
    public func addInternalNote(_ text: String) {
        addFakeEvent(.note, "INTERNAL \(text)")
    }
    
    public func addDebugNote(_ text: String) {
        addFakeEvent(.note, "DEBUG \(text)")
    }
    
    public func addInsulinChange(_ text: String) {
        addFakeEvent(.insulinChange, text)
    }
    
    public func addSiteChange(_ text: String) {
        addFakeEvent(.siteChange, text)
    }
    
    public func addBGReceived(bloodGlucose: Int, comment: String = "") {
        addFakeEvent(.bgReceived, "\(bloodGlucose) \(comment)")
    }
}
