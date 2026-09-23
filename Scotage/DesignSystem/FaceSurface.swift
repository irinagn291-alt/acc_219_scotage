import SwiftUI

extension View {
    func faceReveal(index: Int, reduceMotion: Bool) -> some View {
        modifier(FaceReveal(index: index, reduceMotion: reduceMotion))
    }

    func faceHit() -> some View {
        frame(minWidth: FaceSpace.hit, minHeight: FaceSpace.hit)
            .contentShape(Rectangle())
    }

    func faceSurface() -> some View {
        background(.regularMaterial, in: RoundedRectangle(cornerRadius: FaceRadius.card, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: FaceRadius.card, style: .continuous)
                    .stroke(FaceInk.muted.opacity(0.35), lineWidth: FacePaint.hairline)
            )
    }

    func faceChip() -> some View {
        background(.thinMaterial, in: RoundedRectangle(cornerRadius: FaceRadius.chip, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: FaceRadius.chip, style: .continuous)
                    .stroke(FaceInk.muted.opacity(0.35), lineWidth: FacePaint.hairline)
            )
    }
}

extension Image {
    func faceCutout(maxWidth: CGFloat? = .infinity, maxHeight: CGFloat) -> some View {
        resizable()
            .scaledToFit()
            .frame(maxWidth: maxWidth, maxHeight: maxHeight)
            .clipped()
            .accessibilityHidden(true)
    }
}
