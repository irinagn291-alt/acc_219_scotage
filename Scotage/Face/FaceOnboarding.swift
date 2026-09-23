import SwiftUI

/// Role: Face. One-shot cover. Four pages. Continue full width at the bottom. Skip writes defaults. Re-runnable from Settings.
struct FaceOnboarding: View {
    @Bindable var desk: FaceDesk
    var onSkip: () -> Void
    var onFinish: () -> Void
    @State private var page = 0
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @FocusState private var focused: Bool

    private let lastPage = 3

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Spacer()
                if page < lastPage {
                    Button(FaceCopy.skip, action: onSkip)
                        .font(FaceType.font(.caption, size: typeSize))
                        .foregroundStyle(FaceInk.ink)
                        .faceHit()
                        .buttonStyle(FaceGlyphStyle())
                        .accessibilityLabel(FaceCopy.skip)
                }
            }
            .padding(.horizontal, FaceSpace.outer)

            ViewThatFits(in: .vertical) {
                pageSwitch(showsSpacer: true)
                ScrollView {
                    pageSwitch(showsSpacer: false)
                }
                .scrollIndicators(.hidden)
                .scrollDismissesKeyboard(.interactively)
            }
            .id(page)
            .animation(FaceMotion.snap(reduceMotion), value: page)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)

            HStack(spacing: FaceSpace.inner) {
                ForEach(0 ... lastPage, id: \.self) { index in
                    RoundedRectangle(cornerRadius: FaceRadius.chip, style: .continuous)
                        .fill(index == page ? FaceInk.accent : FaceInk.surface)
                        .frame(
                            width: index == page ? FaceSpace.step(6) : FaceSpace.inner,
                            height: FaceSpace.inner
                        )
                        .accessibilityHidden(true)
                }
            }
            .padding(.horizontal, FaceSpace.outer)
            .padding(.bottom, FaceSpace.inner)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(
                "Page \(FaceFigures.integer(page + 1)) of \(FaceFigures.integer(lastPage + 1))"
            )

            Button(page < lastPage ? FaceCopy.continueVerb : FaceCopy.beginVerb) {
                focused = false
                if page < lastPage {
                    page += 1
                } else {
                    onFinish()
                }
            }
            .buttonStyle(FaceVerbStyle(emphasized: true, isLoading: false, step: .caption))
            .padding(.horizontal, FaceSpace.outer)
            .padding(.bottom, FaceSpace.outer)
        }
        .background(FaceInk.background.ignoresSafeArea())
        .preferredColorScheme(.light)
    }

    @ViewBuilder
    private func pageSwitch(showsSpacer: Bool) -> some View {
        switch page {
        case 0:
            pageBody(
                art: FaceArt.onboarding1,
                headline: FaceCopy.onboarding1Headline,
                line: FaceCopy.onboarding1Line,
                showsSpacer: showsSpacer
            )
        case 1:
            pageBody(
                art: FaceArt.onboarding2,
                headline: FaceCopy.onboarding2Headline,
                line: FaceCopy.onboarding2Line,
                showsSpacer: showsSpacer
            )
        case 2:
            pageBody(
                art: FaceArt.onboarding3,
                headline: FaceCopy.onboarding3Headline,
                line: FaceCopy.onboarding3Line,
                showsSpacer: showsSpacer
            )
        default:
            settingsPage(showsSpacer: showsSpacer)
        }
    }

    private func pageBody(art: String, headline: String, line: String, showsSpacer: Bool) -> some View {
        VStack(alignment: .leading, spacing: FaceSpace.card) {
            Image(art)
                .faceCutout(maxHeight: FaceSpace.step(56))
            Text(headline)
                .font(FaceType.font(.display, size: typeSize))
                .foregroundStyle(FaceInk.ink)
                .lineLimit(3)
                .minimumScaleFactor(0.7)
            Text(line)
                .font(FaceType.font(.caption, size: typeSize))
                .foregroundStyle(FaceInk.ink)
                .lineLimit(4)
            if showsSpacer {
                Spacer(minLength: FaceSpace.inner)
            }
        }
        .padding(.horizontal, FaceSpace.outer)
        .padding(.top, FaceSpace.card)
    }

    private func settingsPage(showsSpacer: Bool) -> some View {
        VStack(alignment: .leading, spacing: FaceSpace.card) {
            Image(FaceArt.twistHero)
                .faceCutout(maxHeight: FaceSpace.step(32))
            Text(FaceCopy.onboarding4Headline)
                .font(FaceType.font(.display, size: typeSize))
                .foregroundStyle(FaceInk.ink)
                .lineLimit(3)
                .minimumScaleFactor(0.7)
            Text(FaceCopy.onboarding4Line)
                .font(FaceType.font(.caption, size: typeSize))
                .foregroundStyle(FaceInk.ink)
                .lineLimit(4)
            Picker(FaceCopy.currencyTitle, selection: $desk.onboardingCurrency) {
                ForEach(currencyCodes, id: \.self) { code in
                    Text(code).tag(code)
                }
            }
            .pickerStyle(.menu)
            .tint(FaceInk.ink)
            .frame(maxWidth: .infinity, minHeight: FaceSpace.hit, alignment: .leading)
            .padding(.horizontal, FaceSpace.card)
            .faceSurface()
            .accessibilityLabel(FaceCopy.currencyTitle)
            TextField(FaceCopy.scotTitle, text: scotBinding)
                .font(FaceType.font(.caption, size: typeSize))
                .keyboardType(.decimalPad)
                .focused($focused)
                .padding(FaceSpace.card)
                .frame(minHeight: FaceSpace.hit)
                .faceSurface()
                .accessibilityLabel(FaceCopy.scotTitle)
            if showsSpacer {
                Spacer(minLength: FaceSpace.inner)
            }
        }
        .padding(.horizontal, FaceSpace.outer)
        .padding(.top, FaceSpace.card)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button(FaceCopy.done) { focused = false }
                    .font(FaceType.font(.caption, size: typeSize))
                    .foregroundStyle(FaceInk.ink)
            }
        }
    }

    private var currencyCodes: [String] {
        var codes = FaceFigures.currencyCodes
        if !codes.contains(desk.onboardingCurrency) {
            codes.insert(desk.onboardingCurrency, at: 0)
        }
        return codes
    }

    private var scotBinding: Binding<String> {
        Binding(
            get: { desk.onboardingScotText },
            set: { next in
                if FaceFigures.allowsAmountDraft(next) {
                    desk.onboardingScotText = next
                }
            }
        )
    }
}
