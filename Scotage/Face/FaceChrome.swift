import SwiftUI
import UIKit

/// Role: Face. Face-locked chrome. The rate Face never leaves. Insights and Settings own the window.
struct FaceChrome: View {
    @State private var desk: FaceDesk
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(desk: FaceDesk = .live()) {
        _desk = State(wrappedValue: desk)
    }

    var body: some View {
        ZStack {
            FaceInk.background.ignoresSafeArea()
            if desk.isBooting {
                Image(FaceArt.splash)
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
                    .clipped()
                    .accessibilityHidden(true)
            } else if desk.showsOnboarding {
                FaceOnboarding(
                    desk: desk,
                    onSkip: { Task { await desk.finishOnboarding(skipped: true) } },
                    onFinish: { Task { await desk.finishOnboarding(skipped: false) } }
                )
            } else {
                LedgerFace(desk: desk)
                    .opacity(desk.sheet == nil && !desk.showsTwist ? 1 : 0)
                    .allowsHitTesting(desk.sheet == nil && !desk.showsTwist)
            }
        }
        .preferredColorScheme(.light)
        .tint(FaceInk.accent)
        .animation(FaceMotion.snap(reduceMotion), value: desk.showsOnboarding)
        .animation(FaceMotion.snap(reduceMotion), value: desk.isBooting)
        .task { await desk.boot() }
        .onChange(of: scenePhase) { _, phase in
            Task { await desk.handle(phase: phase) }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.significantTimeChangeNotification)) { _ in
            Task { await desk.noteCalendarShift() }
        }
        .onReceive(NotificationCenter.default.publisher(for: .NSCalendarDayChanged)) { _ in
            Task { await desk.noteCalendarShift() }
        }
        .fullScreenCover(item: $desk.sheet) { sheet in
            cover(sheet)
        }
        .fullScreenCover(isPresented: $desk.showsTwist) {
            TwistSheet {
                desk.showsTwist = false
            }
        }
    }

    @ViewBuilder
    private func cover(_ sheet: FaceSheet) -> some View {
        switch sheet {
        case .insights:
            InsightsSheet(desk: desk)
        case .settings:
            SettingsSheet(desk: desk)
        }
    }
}
