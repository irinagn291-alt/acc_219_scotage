import SwiftUI

/// Role: Face. Insights cover. ReviewScreen log. QuitMarks, HoldMarks, leftover overrun, mystery-charge flags.
struct InsightsSheet: View {
    @Bindable var desk: FaceDesk
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        FaceSheetHost {
            NavigationStack {
                Group {
                    if desk.fault == FaceCopy.startedEmpty {
                        FaceQuietPage(
                            art: FaceArt.emptyList,
                            headline: FaceCopy.insightsErrorHeadline,
                            line: FaceCopy.startedEmpty,
                            actionTitle: FaceCopy.retry,
                            step: .body
                        ) {
                            Task { await desk.retryLoad() }
                        }
                    } else if desk.insightsIsEmpty {
                        FaceQuietPage(
                            art: FaceArt.emptyList,
                            headline: FaceCopy.insightsEmptyHeadline,
                            line: FaceCopy.insightsEmptyLine,
                            actionTitle: FaceCopy.insightsEmptyAction,
                            step: .body
                        ) {
                            dismiss()
                        }
                    } else {
                        populated
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(FaceInk.background.ignoresSafeArea())
                .navigationTitle(FaceCopy.insightsTitle)
                .navigationBarTitleDisplayMode(.inline)
                .toolbarBackground(FaceInk.background, for: .navigationBar)
                .toolbarBackground(.visible, for: .navigationBar)
                .toolbar { closeToolbar }
            }
        }
    }

    private var populated: some View {
        VStack(alignment: .leading, spacing: FaceSpace.inner) {
            if let fault = desk.fault {
                FaceNotice(message: fault) {
                    Task { await desk.retryLoad() }
                }
                .padding(.horizontal, FaceSpace.outer)
            }
            leftoverReadout
                .padding(.horizontal, FaceSpace.outer)
                .padding(.top, FaceSpace.inner)
            List {
                if !desk.face.quitMarks.isEmpty {
                    Section(FaceCopy.quitsTitle) {
                        ForEach(desk.face.quitMarks.reversed()) { mark in
                            insightButton(
                                title: mark.lotName,
                                value: FaceFigures.money(mark.monthAmount, code: desk.face.currencyCode),
                                flag: FaceCopy.filedQuit,
                                actionName: FaceCopy.seeFace
                            )
                        }
                    }
                }
                if !desk.face.holdMarks.isEmpty {
                    Section(FaceCopy.holdsTitle) {
                        ForEach(desk.face.holdMarks.reversed()) { mark in
                            insightButton(
                                title: mark.lotName,
                                value: FaceCopy.cooledCaption,
                                flag: FaceFigures.dayTitle(mark.dayKey),
                                actionName: FaceCopy.seeFace
                            )
                        }
                    }
                }
                if !desk.mysteryLots.isEmpty {
                    Section(FaceCopy.mysteryTitle) {
                        ForEach(desk.mysteryLots) { lot in
                            insightButton(
                                title: lot.name,
                                value: FaceFigures.monthAmount(lot, code: desk.face.currencyCode),
                                flag: FaceCopy.mysteryReason(
                                    lot,
                                    sharedDay: desk.ledgerFrame.sharedDayIDs.contains(lot.id)
                                ),
                                actionName: FaceCopy.inspectLot
                            )
                        }
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .scrollDismissesKeyboard(.interactively)
            .scrollIndicators(.hidden)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(FaceInk.background)
    }

    private var leftoverReadout: some View {
        VStack(alignment: .leading, spacing: FaceSpace.step(1)) {
            Text(FaceCopy.leftoverTitle)
                .font(FaceType.font(.caption, size: typeSize))
                .foregroundStyle(FaceInk.ink)
                .lineLimit(1)
            Text(FaceFigures.money(desk.leftoverOverrun, code: desk.face.currencyCode))
                .font(FaceType.font(.display, size: typeSize).monospacedDigit())
                .foregroundStyle(FaceInk.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(FaceCopy.leftoverLine)
                .font(FaceType.font(.caption, size: typeSize))
                .foregroundStyle(FaceInk.ink)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    private func insightButton(
        title: String,
        value: String,
        flag: String,
        actionName: String
    ) -> some View {
        Button {
            dismiss()
        } label: {
            HStack(alignment: .firstTextBaseline, spacing: FaceSpace.inner) {
                VStack(alignment: .leading, spacing: FaceSpace.step(1)) {
                    Text(title)
                        .font(FaceType.font(.body, size: typeSize))
                        .foregroundStyle(FaceInk.ink)
                        .lineLimit(2)
                        .minimumScaleFactor(0.85)
                    Text(flag)
                        .font(FaceType.font(.caption, size: typeSize))
                        .foregroundStyle(FaceInk.ink)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(actionName)
                        .font(FaceType.font(.caption, size: typeSize))
                        .foregroundStyle(FaceInk.ink)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Text(value)
                    .font(FaceType.font(.body, size: typeSize).monospacedDigit())
                    .foregroundStyle(FaceInk.ink)
                    .lineLimit(1)
                    .layoutPriority(1)
            }
            .frame(maxWidth: .infinity, minHeight: FaceSpace.hit, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(FaceQuietStyle(step: .body))
        .listRowInsets(EdgeInsets(top: FaceSpace.inner, leading: FaceSpace.outer, bottom: FaceSpace.inner, trailing: FaceSpace.outer))
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
        .accessibilityLabel("\(title), \(value), \(flag)")
        .accessibilityHint(actionName)
    }

    @ToolbarContentBuilder
    private var closeToolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .frame(minWidth: FaceSpace.hit, minHeight: FaceSpace.hit)
                    .contentShape(Rectangle())
            }
            .buttonStyle(FaceGlyphStyle())
            .accessibilityLabel(FaceCopy.close)
        }
    }
}
