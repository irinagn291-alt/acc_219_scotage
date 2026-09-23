import Foundation

/// Role: Face. Tactical copy. Status first. Periods, never an em dash. The ui axis is never a title.
enum FaceCopy {
    static let jobHeadline = "Tap the aimed lot."
    static let jobLine = "The hand points at the overrun. That tap files it quit."
    static let jobBare = "Load sits inside the Scot. Add a lot or lower the pin."
    static let jobEased = "Load sits at the Scot. The month holds."
    static let jobVacantHeadline = "No lots this month."
    static let jobVacantLine = "Add one to see the monthly load."
    static let vacantAction = "Add a lot"
    static let addLot = "Add a lot"
    static let addChip = "Add"
    static let cancel = "Cancel"
    static let saveLot = "Save lot"
    static let namePlaceholder = "Lot name"
    static let amountPlaceholder = "Amount"
    static let periodTitle = "Period"
    static let chargeTitle = "Next charge"
    static let insightsTitle = "Insights"
    static let settingsTitle = "Settings"
    static let twistTitle = "Aim then quit"
    static let close = "Close"
    static let done = "Done"
    static let retry = "Retry"
    static let skip = "Skip"
    static let continueVerb = "Continue"
    static let beginVerb = "Begin"
    static let writeFailed = "Could not save the face. Try again."
    static let recovered = "Restored the last good face."
    static let startedEmpty = "The saved face could not be read. Starting empty."
    static let loadFailed = "The face could not be read."
    static let insightsEmptyHeadline = "No quits filed yet."
    static let insightsEmptyLine = "Tap the aimed lot on the face, then read it here."
    static let insightsEmptyAction = "Back to the face"
    static let insightsErrorHeadline = "Insights could not load."
    static let settingsEmptyHeadline = "Nothing stored yet."
    static let settingsEmptyLine = "Add a lot on the face, then set the Scot."
    static let settingsErrorHeadline = "Settings could not load."
    static let leftoverTitle = "Leftover overrun"
    static let leftoverLine = "Live load past the Scot."
    static let quitsTitle = "Quit marks"
    static let holdsTitle = "Cooled misses"
    static let mysteryTitle = "Mystery charges"
    static let seeFace = "See the face"
    static let filedQuit = "Filed quit"
    static let inspectLot = "Inspect this lot"
    static let currencyTitle = "Currency"
    static let scotTitle = "Scot pin"
    static let reminderTitle = "Local reminder"
    static let reminderTime = "Reminder time"
    static let contactTitle = "Contact"
    static let contactDetail = "scotage-face.pro/contact-us"
    static let replayOnboarding = "Re-run onboarding"
    static let resetTitle = "Reset all data"
    static let resetConfirm = "Reset all data?"
    static let resetMessage = "This removes lots, quit marks, hold marks, and the Scot on this device."
    static let resetAction = "Reset all data"
    static let twistHeadline = "Only the aimed lot can quit."
    static let twistBody =
        "The hand points at the largest overrun lot. That tap files a QuitMark and the needle falls. Any other tap cools the arc and leaves the hand."
    static let twistStay =
        "Insights lists quits, cooled misses, leftover overrun, and mystery charges. Settings holds currency, the Scot, and a local reminder."
    static let onboarding1Headline = "This month sits on a rate face."
    static let onboarding1Line = "Lots that bill now ring the rim. The needle is the period-normalized month total."
    static let onboarding2Headline = "Tap the lot under the hand."
    static let onboarding2Line = "That lot files as quit. The needle drops. Cancel-savings rise."
    static let onboarding3Headline = "A miss cools the wrong arc."
    static let onboarding3Line = "The hand stays. Insights keeps the cooled miss and the leftover overrun."
    static let onboarding4Headline = "Set the Scot you can bear."
    static let onboarding4Line = "The pin marks that month. Currency stays on this device."
    static let openInsights = "Open Insights"
    static let openSettings = "Open Settings"
    static let openTwist = "How Aim then Quit works"
    static let monthCaption = "This month"
    static let yearCaption = "Year"
    static let scotCaption = "Scot"
    static let savedCaption = "Cancel-savings"
    static let aimedCaption = "Aimed"
    static let cooledCaption = "Cooled"
    static let mysteryCaption = "Mystery"
    static let mysteryNoPeriod = "No period"
    static let mysterySharedDay = "Shared charge day"
    static let weekly = "Weekly"
    static let monthly = "Monthly"
    static let yearly = "Yearly"
    static let unspecified = "No period"

    static func job(on frame: LedgerFrame) -> String {
        if let status = frame.status, !status.isEmpty {
            return status
        }
        switch frame.precept {
        case .vacant:
            return jobVacantLine
        case .bare:
            return jobBare
        case .eased:
            return jobEased
        case .aimed:
            if let name = frame.aimedName, !name.isEmpty {
                return aimedJob(name)
            }
            return jobLine
        }
    }

    static func aimedJob(_ name: String) -> String {
        "Tap \(name) to file it quit."
    }

    static func cooled(_ name: String) -> String {
        "Cooled \(name). The hand stays."
    }

    static func filed(_ name: String) -> String {
        "Filed \(name). Needle dropped."
    }

    static func periodWord(_ period: LotPeriod) -> String {
        switch period {
        case .weekly:
            return weekly
        case .monthly:
            return monthly
        case .yearly:
            return yearly
        case .unspecified:
            return unspecified
        }
    }

    static func rimCaption(period: LotPeriod, aimed: Bool, cooled: Bool) -> String {
        var marks = [periodWord(period)]
        if aimed { marks.append(aimedCaption) }
        if cooled { marks.append(cooledCaption) }
        return marks.joined(separator: ", ")
    }

    static func preceptWord(_ precept: Precept) -> String {
        switch precept {
        case .vacant:
            return "Vacant"
        case .bare:
            return "Bare"
        case .aimed:
            return "Aimed"
        case .eased:
            return "Eased"
        }
    }

    static func fault(_ error: Error) -> String {
        guard let fault = error as? FaceFault else { return writeFailed }
        switch fault {
        case .vacant:
            return "The face is vacant. Add a lot."
        case .quitOnBare:
            return "Aim first. Then tap the lot."
        case .alreadyAimed:
            return "The hand already aims."
        case .noOverrun:
            return "No lot sits past the Scot."
        case .unknownLot:
            return "That lot is not on the face."
        case .blankLot:
            return "A lot needs a name and a charge day."
        case .negativeAmount:
            return "Amount must be above zero."
        case .notAimed:
            return "The face is not aimed. Quit is refused."
        }
    }

    static func warning(_ warning: FaceWarning) -> String {
        switch warning {
        case .recoveredFromBackup:
            return recovered
        case .startedEmpty:
            return startedEmpty
        }
    }

    static func mysteryReason(_ lot: Lot, sharedDay: Bool) -> String {
        if lot.period == .unspecified {
            return mysteryNoPeriod
        }
        if sharedDay {
            return mysterySharedDay
        }
        return mysteryCaption
    }
}
