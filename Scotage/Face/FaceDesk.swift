import Foundation
import Observation
import SwiftUI

/// Role: Face. Observable fold over FaceStore. Views call tap, add, and aim through this seam and never touch UserDefaults.
@MainActor
@Observable
final class FaceDesk {
    let store: FaceStore
    private let calendar: Calendar
    private let clock: @Sendable () -> Date
    private let plantsDemo: Bool

    private(set) var face: Face
    var isBooting: Bool
    var showsOnboarding: Bool
    var sheet: FaceSheet?
    var showsTwist: Bool
    var recoveredNotice: Bool
    var fault: String?
    var status: String?
    var tapBusy: Bool
    var addBusy: Bool
    var saveBusy: Bool
    var showSuccess: Bool
    var commitPulse: Int
    var isComposing: Bool
    var draftName: String
    var draftAmountText: String
    var draftPeriod: LotPeriod
    var draftCharge: Date
    var draftScotText: String
    var onboardingScotText: String
    var onboardingCurrency: String

    private var reviewConsumed: Bool
    private var tapInFlight: Bool
    private var addInFlight: Bool
    private var successTask: Task<Void, Never>?

    init(
        store: FaceStore,
        calendar: Calendar = .current,
        now: @escaping @Sendable () -> Date = { Date() },
        plantsDemo: Bool = true,
        isBooting: Bool = true
    ) {
        self.store = store
        self.calendar = calendar
        self.clock = now
        self.plantsDemo = plantsDemo
        self.face = .empty
        self.isBooting = isBooting
        self.showsOnboarding = false
        self.sheet = nil
        self.showsTwist = false
        self.recoveredNotice = false
        self.fault = nil
        self.status = nil
        self.tapBusy = false
        self.addBusy = false
        self.saveBusy = false
        self.showSuccess = false
        self.commitPulse = 0
        self.isComposing = false
        self.draftName = ""
        self.draftAmountText = ""
        self.draftPeriod = .monthly
        self.draftCharge = now()
        self.draftScotText = ""
        self.onboardingScotText = "90"
        self.onboardingCurrency = "USD"
        self.reviewConsumed = false
        self.tapInFlight = false
        self.addInFlight = false
    }

    static func live() -> FaceDesk {
        FaceDesk(store: FaceStore.applicationSupportStore())
    }

    var now: Date { clock() }

    var liveLots: [Lot] {
        face.liveLots(at: now, calendar: calendar).sorted { lhs, rhs in
            if lhs.nextChargeDay != rhs.nextChargeDay {
                return lhs.nextChargeDay < rhs.nextChargeDay
            }
            return lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
        }
    }

    var isVacantFace: Bool {
        liveLots.isEmpty && !isComposing
    }

    var insightsIsEmpty: Bool {
        face.quitMarks.isEmpty
            && face.holdMarks.isEmpty
            && leftoverOverrun <= 0
            && mysteryLots.isEmpty
    }

    var settingsIsEmpty: Bool {
        face.lots.isEmpty && face.quitMarks.isEmpty && face.holdMarks.isEmpty
    }

    var leftoverOverrun: Double {
        face.leftoverOverrun(at: now, calendar: calendar)
    }

    var mysteryLots: [Lot] {
        face.mysteryLots(at: now, calendar: calendar)
    }

    var quitEnabled: Bool {
        face.canQuitAimed && !tapInFlight
    }

    var ledgerFrame: LedgerFrame {
        let live = liveLots
        let aimed = face.aimedLot(at: now, calendar: calendar)
        let mystery = Set(mysteryLots.map(\.id))
        let dayCounts = Dictionary(grouping: live, by: \.nextChargeDay).mapValues(\.count)
        let shared = Set(live.filter { (dayCounts[$0.nextChargeDay] ?? 0) > 1 }.map(\.id))
        return LedgerFrame(
            lots: live,
            aimedID: aimed?.id,
            aimedName: aimed?.name,
            cooledIDs: Set(face.holdMarks.map(\.lotID)),
            mysteryIDs: mystery,
            sharedDayIDs: shared,
            liveLoad: face.liveLoad(at: now, calendar: calendar),
            yearLoad: face.yearInscription(at: now, calendar: calendar),
            scot: face.scot.amount,
            cancelSavings: face.cancelSavings,
            currencyCode: face.currencyCode,
            precept: face.precept,
            composing: isComposing,
            status: status,
            isFaulted: fault != nil
        )
    }

    func boot(arguments: [String] = ProcessInfo.processInfo.arguments) async {
        guard isBooting else { return }
        let loaded = await store.load()
        face = loaded.face
        recoveredNotice = loaded.warning != nil
        if let warning = loaded.warning {
            fault = FaceCopy.warning(warning)
        }
        if plantsDemo {
            do {
                _ = try await store.seedDemoIfNeeded(now: now, calendar: calendar)
            } catch {
                fault = FaceCopy.writeFailed
            }
            await refreshFromStore()
        }
        draftScotText = FaceFigures.decimal(face.scot.amount)
        draftCharge = now
        onboardingCurrency = face.currencyCode
        showsOnboarding = !face.onboardingComplete
        isBooting = false
        await ensureAimed()
        if !showsOnboarding {
            applyReview(arguments)
        }
    }

    func flush() async {
        do {
            try await store.flush()
            if fault == FaceCopy.writeFailed {
                fault = nil
            }
            await refreshFromStore()
        } catch {
            fault = FaceCopy.writeFailed
            await refreshFromStore()
        }
    }

    func retryLoad() async {
        let loaded = await store.load()
        face = loaded.face
        recoveredNotice = loaded.warning != nil
        if let warning = loaded.warning {
            fault = FaceCopy.warning(warning)
        } else {
            fault = nil
        }
        await ensureAimed()
    }

    func handle(phase: ScenePhase) async {
        switch phase {
        case .inactive, .background:
            await flush()
        case .active:
            await refreshFromStore()
            await ensureAimed()
        @unknown default:
            break
        }
    }

    func finishOnboarding(skipped: Bool) async {
        do {
            if skipped {
                if face.currencyCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    face = try await store.setCurrency("USD")
                }
                if face.scot.amount == 0, face.lots.isEmpty {
                    face = try await store.setScot(Scot(amount: 90), at: now, calendar: calendar)
                }
            } else {
                let code = onboardingCurrency.trimmingCharacters(in: .whitespacesAndNewlines)
                if !code.isEmpty {
                    face = try await store.setCurrency(code)
                }
                if let amount = FaceFigures.parseAmount(onboardingScotText) {
                    face = try await store.setScot(Scot(amount: amount), at: now, calendar: calendar)
                } else if face.scot.amount == 0 {
                    face = try await store.setScot(Scot(amount: 90), at: now, calendar: calendar)
                }
            }
            face = try await store.setOnboardingComplete(true)
            try await store.flush()
            fault = nil
        } catch {
            fault = FaceCopy.writeFailed
            await refreshFromStore()
        }
        draftScotText = FaceFigures.decimal(face.scot.amount)
        showsOnboarding = false
        await ensureAimed()
        applyReview(ProcessInfo.processInfo.arguments)
    }

    func replayOnboarding() {
        sheet = nil
        showsTwist = false
        showsOnboarding = true
        onboardingCurrency = face.currencyCode
        onboardingScotText = face.scot.amount > 0 ? FaceFigures.decimal(face.scot.amount) : "90"
    }

    func present(_ sheet: FaceSheet) {
        showsTwist = false
        self.sheet = sheet
    }

    func presentTwist() {
        sheet = nil
        showsTwist = true
    }

    func beginCompose() {
        isComposing = true
        if draftName.isEmpty {
            draftAmountText = ""
            draftPeriod = .monthly
            draftCharge = now
        }
        status = nil
    }

    func cancelCompose() {
        isComposing = false
        draftName = ""
        draftAmountText = ""
        draftPeriod = .monthly
        status = nil
    }

    func tapLot(_ lotID: UUID) async {
        guard !tapInFlight else { return }
        tapInFlight = true
        let pulse = Task {
            try await Task.sleep(for: .milliseconds(150))
            if !Task.isCancelled { tapBusy = true }
        }
        let beforeQuits = face.quitMarks.count
        let name = face.lots.first { $0.id == lotID }?.name ?? ""
        do {
            face = try await store.tap(lotID: lotID, at: now, calendar: calendar)
            fault = nil
            if face.quitMarks.count > beforeQuits {
                status = FaceCopy.filed(name)
                commitPulse += 1
                flashSuccess()
            } else {
                status = FaceCopy.cooled(name)
            }
        } catch {
            fault = FaceCopy.fault(error)
            await refreshFromStore()
        }
        pulse.cancel()
        tapBusy = false
        tapInFlight = false
        await ensureAimed()
    }

    func addDraft() async {
        guard !addInFlight else { return }
        let name = draftName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let amount = FaceFigures.parseAmount(draftAmountText) else {
            fault = FaceCopy.fault(FaceFault.negativeAmount)
            return
        }
        addInFlight = true
        let pulse = Task {
            try await Task.sleep(for: .milliseconds(150))
            if !Task.isCancelled { addBusy = true }
        }
        let lot = Lot(
            name: name,
            amount: amount,
            period: draftPeriod,
            nextChargeDay: FaceDay.key(for: draftCharge, calendar: calendar)
        )
        do {
            face = try await store.addLot(lot, at: now, calendar: calendar)
            fault = nil
            status = nil
            cancelCompose()
            commitPulse += 1
        } catch {
            fault = FaceCopy.fault(error)
            await refreshFromStore()
        }
        pulse.cancel()
        addBusy = false
        addInFlight = false
        await ensureAimed()
    }

    func setCurrency(_ code: String) async {
        do {
            face = try await store.setCurrency(code)
            fault = nil
        } catch {
            fault = FaceCopy.fault(error)
            await refreshFromStore()
        }
    }

    func commitScot() async {
        guard let amount = FaceFigures.parseNonNegative(draftScotText) else {
            fault = FaceCopy.fault(FaceFault.negativeAmount)
            return
        }
        do {
            face = try await store.setScot(Scot(amount: amount), at: now, calendar: calendar)
            fault = nil
            draftScotText = FaceFigures.decimal(face.scot.amount)
            commitPulse += 1
        } catch {
            fault = FaceCopy.fault(error)
            await refreshFromStore()
        }
        await ensureAimed()
    }

    func setReminder(_ reminder: FaceReminder) async {
        do {
            face = try await store.setReminder(reminder)
            fault = nil
        } catch {
            fault = FaceCopy.writeFailed
            await refreshFromStore()
        }
    }

    func resetAllData() async {
        successTask?.cancel()
        do {
            try await store.resetAllData()
            await refreshFromStore()
            sheet = nil
            showsTwist = false
            isComposing = false
            draftName = ""
            draftAmountText = ""
            draftPeriod = .monthly
            draftScotText = "0"
            recoveredNotice = false
            showSuccess = false
            status = nil
            fault = nil
            showsOnboarding = true
            reviewConsumed = true
            onboardingCurrency = "USD"
            onboardingScotText = "90"
        } catch {
            fault = FaceCopy.writeFailed
            await refreshFromStore()
        }
    }

    func applyReviewIfNeeded(_ arguments: [String]) {
        applyReview(arguments)
    }

    func noteCalendarShift() async {
        await refreshFromStore()
        await ensureAimed()
    }

    private func applyReview(_ arguments: [String]) {
        let alreadyConsumed = reviewConsumed
        var consumed = reviewConsumed
        let review = FaceReview.consume(
            arguments: arguments,
            onboardingComplete: face.onboardingComplete,
            consumed: &consumed
        )
        reviewConsumed = consumed
        if let review {
            switch review {
            case .today:
                sheet = nil
                showsTwist = false
            case .log:
                showsTwist = false
                sheet = .insights
            case .goals:
                showsTwist = false
                sheet = .settings
            }
            return
        }
        guard !alreadyConsumed, consumed, let slug = reviewSlug(arguments) else { return }
        if FaceReview.isLedgerSlug(slug) {
            sheet = nil
            showsTwist = false
            return
        }
        if let cover = FaceReview.sheet(forSlug: slug) {
            showsTwist = false
            sheet = cover
            return
        }
        if let extra = FaceReview.extraLaunch(forSlug: slug) {
            switch extra {
            case .insights:
                showsTwist = false
                sheet = .insights
            case .settings:
                showsTwist = false
                sheet = .settings
            case .onboarding:
                sheet = nil
                showsTwist = false
                showsOnboarding = true
            case .twist:
                sheet = nil
                showsOnboarding = false
                showsTwist = true
            }
        }
    }

    private func reviewSlug(_ arguments: [String]) -> String? {
        guard let index = arguments.firstIndex(of: "-ReviewScreen") else { return nil }
        let next = arguments.index(after: index)
        guard arguments.indices.contains(next) else { return nil }
        return arguments[next]
    }

    private func ensureAimed() async {
        guard face.canAim else { return }
        do {
            face = try await store.aim(at: now, calendar: calendar)
        } catch {
            // Bare with no overrun stays Bare. Vacant stays Vacant.
        }
    }

    private func flashSuccess() {
        successTask?.cancel()
        showSuccess = true
        successTask = Task {
            try? await Task.sleep(for: .milliseconds(1200))
            if !Task.isCancelled {
                showSuccess = false
            }
        }
    }

    private func refreshFromStore() async {
        face = await store.face()
        if let write = await store.lastWriteError, !write.isEmpty {
            fault = FaceCopy.writeFailed
        }
        draftScotText = FaceFigures.decimal(face.scot.amount)
    }
}
