import SwiftUI

/// Role: DesignSystem. Soft-card primary control. Default, pressed, disabled, loading. Delete does not wear accent.
struct FaceVerbStyle: ButtonStyle {
    var emphasized: Bool = true
    var isLoading: Bool = false
    var step: FaceType.Step = .caption

    func makeBody(configuration: Configuration) -> some View {
        FaceVerbBody(
            configuration: configuration,
            emphasized: emphasized,
            isLoading: isLoading,
            step: step
        )
    }
}

private struct FaceVerbBody: View {
    let configuration: ButtonStyle.Configuration
    let emphasized: Bool
    let isLoading: Bool
    let step: FaceType.Step
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.isFocused) private var isFocused
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        let pressed = configuration.isPressed
        HStack(spacing: FaceSpace.inner) {
            if isLoading {
                ProgressView()
                    .tint(labelInk)
            }
            configuration.label
        }
        .font(FaceType.font(step, size: typeSize))
        .foregroundStyle(labelInk)
        .frame(maxWidth: .infinity)
        .frame(minHeight: FaceSpace.hit)
        .padding(.horizontal, FaceSpace.card)
        .background(
            fill,
            in: RoundedRectangle(cornerRadius: FaceRadius.card, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: FaceRadius.card, style: .continuous)
                .stroke(
                    isFocused ? FaceInk.ink : FaceInk.muted.opacity(emphasized ? 0 : 0.35),
                    lineWidth: isFocused ? 2 : FacePaint.hairline
                )
        )
        .contentShape(RoundedRectangle(cornerRadius: FaceRadius.card, style: .continuous))
        .scaleEffect(pressed && isEnabled ? FaceMotion.pressScale(reduceMotion) : 1)
        .opacity(visualOpacity(pressed: pressed))
        .animation(FaceMotion.snap(reduceMotion), value: pressed)
        .animation(FaceMotion.snap(reduceMotion), value: isEnabled)
        .animation(FaceMotion.snap(reduceMotion), value: isLoading)
        .animation(FaceMotion.snap(reduceMotion), value: isFocused)
    }

    private var fill: Color {
        if !isEnabled {
            return FaceInk.muted.opacity(0.28)
        }
        return emphasized ? FaceInk.accent : FaceInk.surface
    }

    private var labelInk: Color {
        if !isEnabled {
            return FaceInk.ink.opacity(0.7)
        }
        return emphasized ? FaceInk.surface : FaceInk.ink
    }

    private func visualOpacity(pressed: Bool) -> Double {
        if !isEnabled { return 0.55 }
        if isLoading { return 0.7 }
        if pressed { return 0.88 }
        return 1
    }
}

/// Role: DesignSystem. Quiet chrome. Never the live-verb accent.
struct FaceQuietStyle: ButtonStyle {
    var destructive: Bool = false
    var step: FaceType.Step = .caption
    var compact: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        FaceQuietBody(
            configuration: configuration,
            destructive: destructive,
            step: step,
            compact: compact
        )
    }
}

private struct FaceQuietBody: View {
    let configuration: ButtonStyle.Configuration
    let destructive: Bool
    let step: FaceType.Step
    let compact: Bool
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.isFocused) private var isFocused
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        let pressed = configuration.isPressed
        let radius = compact ? FaceRadius.chip : FaceRadius.card
        configuration.label
            .font(FaceType.font(step, size: typeSize))
            .foregroundStyle(FaceInk.ink)
            .frame(maxWidth: .infinity)
            .frame(minHeight: FaceSpace.hit)
            .padding(.horizontal, compact ? FaceSpace.inner : FaceSpace.card)
            .background {
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(compact ? Material.thin : Material.regular)
            }
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .stroke(
                        isFocused ? FaceInk.ink : FaceInk.muted.opacity(0.35),
                        lineWidth: isFocused ? 2 : FacePaint.hairline
                    )
            )
            .contentShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
            .scaleEffect(pressed && isEnabled ? FaceMotion.pressScale(reduceMotion) : 1)
            .opacity(quietOpacity(pressed: pressed))
            .animation(FaceMotion.snap(reduceMotion), value: pressed)
            .animation(FaceMotion.snap(reduceMotion), value: isEnabled)
    }

    private func quietOpacity(pressed: Bool) -> Double {
        if !isEnabled { return 0.45 }
        if pressed { return 0.88 }
        return destructive ? 0.92 : 1
    }
}

/// Role: DesignSystem. Icon-only chrome. Hit the whole 44pt tile.
struct FaceGlyphStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        FaceGlyphBody(configuration: configuration)
    }
}

private struct FaceGlyphBody: View {
    let configuration: ButtonStyle.Configuration
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.isFocused) private var isFocused
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let pressed = configuration.isPressed
        configuration.label
            .frame(minWidth: FaceSpace.hit, minHeight: FaceSpace.hit)
            .background(
                FaceInk.surface,
                in: RoundedRectangle(cornerRadius: FaceRadius.chip, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: FaceRadius.chip, style: .continuous)
                    .stroke(
                        isFocused ? FaceInk.ink : FaceInk.muted.opacity(0.35),
                        lineWidth: isFocused ? 2 : FacePaint.hairline
                    )
            )
            .contentShape(RoundedRectangle(cornerRadius: FaceRadius.chip, style: .continuous))
            .scaleEffect(pressed && isEnabled ? FaceMotion.pressScale(reduceMotion) : 1)
            .opacity(!isEnabled ? 0.42 : (pressed ? 0.88 : 1))
            .animation(FaceMotion.snap(reduceMotion), value: pressed)
            .animation(FaceMotion.snap(reduceMotion), value: isEnabled)
    }
}

/// Role: DesignSystem. Sheet fade. Reduce Motion is opacity only. Scale 0.96 to 1.
struct FaceSheetHost<Content: View>: View {
    @ViewBuilder var content: Content
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appeared = false

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(FaceInk.background.ignoresSafeArea())
            .preferredColorScheme(.light)
            .tint(FaceInk.accent)
            .opacity(appeared ? 1 : 0)
            .scaleEffect(appeared || reduceMotion ? 1 : 0.96)
            .onAppear {
                withAnimation(FaceMotion.snap(reduceMotion)) {
                    appeared = true
                }
            }
    }
}

/// Role: DesignSystem. Full-page empty or error. Cutout, one headline, one line, bottom full-width CTA.
struct FaceQuietPage: View {
    let art: String
    let headline: String
    let line: String
    let actionTitle: String
    var isLoading: Bool = false
    var step: FaceType.Step = .caption
    let action: () -> Void
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        VStack(alignment: .leading, spacing: FaceSpace.card) {
            ViewThatFits(in: .vertical) {
                copyStack(showsSpacer: true)
                ScrollView {
                    copyStack(showsSpacer: false)
                }
                .scrollIndicators(.hidden)
                .scrollDismissesKeyboard(.interactively)
            }
            Button(actionTitle, action: action)
                .buttonStyle(FaceVerbStyle(emphasized: true, isLoading: isLoading, step: step))
                .faceHit()
        }
        .padding(.horizontal, FaceSpace.outer)
        .padding(.top, FaceSpace.card)
        .padding(.bottom, FaceSpace.outer)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(FaceInk.background)
    }

    private func copyStack(showsSpacer: Bool) -> some View {
        VStack(alignment: .leading, spacing: FaceSpace.card) {
            Image(art)
                .faceCutout(maxHeight: FaceSpace.step(44))
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
    }
}

/// Role: DesignSystem. Calm error with Retry. Hairline, not a tinted bar.
struct FaceNotice: View {
    let message: String
    var retryTitle: String = FaceCopy.retry
    var retry: (() -> Void)?
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        HStack(alignment: .center, spacing: FaceSpace.inner) {
            Text(message)
                .font(FaceType.font(.caption, size: typeSize))
                .foregroundStyle(FaceInk.ink)
                .frame(maxWidth: .infinity, alignment: .leading)
            if let retry {
                Button(retryTitle, action: retry)
                    .font(FaceType.font(.caption, size: typeSize))
                    .foregroundStyle(FaceInk.ink)
                    .faceHit()
                    .buttonStyle(FaceGlyphStyle())
                    .accessibilityLabel(retryTitle)
            }
        }
        .padding(FaceSpace.card)
        .faceSurface()
    }
}
