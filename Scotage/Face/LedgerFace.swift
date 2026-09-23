import SwiftUI

/// Role: Face. Root rate face. ReviewScreen today. Needle, Scot pin, rim Lots, add-on-rim composer. Vacant is a full page.
struct LedgerFace: View {
    @Bindable var desk: FaceDesk
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: FaceSpace.inner) {
                chrome
                if desk.fault == FaceCopy.startedEmpty {
                    FaceQuietPage(
                        art: FaceArt.emptyHome,
                        headline: FaceCopy.loadFailed,
                        line: FaceCopy.startedEmpty,
                        actionTitle: FaceCopy.retry
                    ) {
                        Task { await desk.retryLoad() }
                    }
                } else if desk.isVacantFace {
                    vacant
                } else {
                    populated
                }
            }
            .padding(.top, FaceSpace.inner)
            .padding(.bottom, FaceSpace.inner)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(FaceInk.background.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
        }
        .sensoryFeedback(.impact(weight: .medium), trigger: desk.commitPulse)
        .overlay {
            if desk.showSuccess {
                Image(FaceArt.successMark)
                    .faceCutout(maxHeight: FaceSpace.step(20))
                    .padding(FaceSpace.outer)
                    .faceSurface()
                    .accessibilityHidden(true)
            }
        }
        .animation(FaceMotion.snap(reduceMotion), value: desk.face.precept)
        .animation(FaceMotion.snap(reduceMotion), value: desk.showSuccess)
        .animation(FaceMotion.snap(reduceMotion), value: desk.isComposing)
    }

    private var chrome: some View {
        HStack(alignment: .center, spacing: FaceSpace.inner) {
            Button {
                desk.present(.insights)
            } label: {
                Image(systemName: "list.bullet")
                    .foregroundStyle(FaceInk.ink)
                    .frame(minWidth: FaceSpace.hit, minHeight: FaceSpace.hit)
                    .contentShape(Rectangle())
            }
            .buttonStyle(FaceGlyphStyle())
            .accessibilityLabel(FaceCopy.openInsights)

            Text(FaceCopy.job(on: desk.ledgerFrame))
                .font(FaceType.font(.headline, size: typeSize))
                .foregroundStyle(FaceInk.ink)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.85)
                .padding(.horizontal, FaceSpace.inner)
                .frame(maxWidth: .infinity, minHeight: FaceSpace.hit)
                .background(
                    FaceInk.surface,
                    in: RoundedRectangle(cornerRadius: FaceRadius.chip, style: .continuous)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: FaceRadius.chip, style: .continuous)
                        .stroke(FaceInk.muted.opacity(0.35), lineWidth: FacePaint.hairline)
                )
                .accessibilityAddTraits(.isHeader)

            Button {
                desk.present(.settings)
            } label: {
                Image(systemName: "gearshape")
                    .foregroundStyle(FaceInk.ink)
                    .frame(minWidth: FaceSpace.hit, minHeight: FaceSpace.hit)
                    .contentShape(Rectangle())
            }
            .buttonStyle(FaceGlyphStyle())
            .accessibilityLabel(FaceCopy.openSettings)
        }
        .padding(.horizontal, FaceSpace.outer)
        .faceReveal(index: 0, reduceMotion: reduceMotion)
    }

    private var vacant: some View {
        FaceQuietPage(
            art: FaceArt.emptyHome,
            headline: FaceCopy.jobVacantHeadline,
            line: FaceCopy.jobVacantLine,
            actionTitle: FaceCopy.vacantAction
        ) {
            desk.beginCompose()
        }
        .faceReveal(index: 1, reduceMotion: reduceMotion)
    }

    private var populated: some View {
        VStack(alignment: .leading, spacing: FaceSpace.inner) {
            if let fault = desk.fault {
                FaceNotice(message: fault) {
                    Task { await desk.retryLoad() }
                }
                .padding(.horizontal, FaceSpace.outer)
                .faceReveal(index: 1, reduceMotion: reduceMotion)
            }
            LedgerBoard(desk: desk, reduceMotion: reduceMotion)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
                .faceReveal(index: 2, reduceMotion: reduceMotion)
        }
    }
}
