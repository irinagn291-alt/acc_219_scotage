import SwiftUI

/// Role: Face. Twist screen of its own. Aim-then-quit also lives on LedgerFace as the aimed arc.
struct TwistSheet: View {
    var onClose: () -> Void
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        FaceSheetHost {
            NavigationStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: FaceSpace.card) {
                        Image(FaceArt.twistHero)
                            .faceCutout(maxHeight: FaceSpace.step(44))
                            .frame(maxWidth: .infinity)
                        Text(FaceCopy.twistHeadline)
                            .font(FaceType.font(.display, size: typeSize))
                            .foregroundStyle(FaceInk.ink)
                            .lineLimit(3)
                            .minimumScaleFactor(0.7)
                        Text(FaceCopy.twistBody)
                            .font(FaceType.font(.body, size: typeSize))
                            .foregroundStyle(FaceInk.ink)
                        Text(FaceCopy.twistStay)
                            .font(FaceType.font(.caption, size: typeSize))
                            .foregroundStyle(FaceInk.muted)
                    }
                    .padding(.horizontal, FaceSpace.outer)
                    .padding(.top, FaceSpace.card)
                    .padding(.bottom, FaceSpace.outer)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .scrollIndicators(.hidden)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(FaceInk.background.ignoresSafeArea())
                .navigationTitle(FaceCopy.twistTitle)
                .navigationBarTitleDisplayMode(.inline)
                .toolbarBackground(FaceInk.background, for: .navigationBar)
                .toolbarBackground(.visible, for: .navigationBar)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(action: onClose) {
                            Image(systemName: "xmark")
                                .frame(minWidth: FaceSpace.hit, minHeight: FaceSpace.hit)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(FaceGlyphStyle())
                        .accessibilityLabel(FaceCopy.close)
                    }
                }
            }
        }
    }
}
