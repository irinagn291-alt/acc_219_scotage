import SwiftUI

/// Role: Lot. Expanded rim composer in the same snapshot. Amount, period, next charge day. No pushed detail.
struct LotComposerForm: View {
    @Bindable var desk: FaceDesk
    @Environment(\.dynamicTypeSize) private var typeSize
    @FocusState private var focused: Field?

    private enum Field: Hashable {
        case name
        case amount
    }

    var body: some View {
        VStack(alignment: .leading, spacing: FaceSpace.inner) {
            Text(FaceCopy.addLot)
                .font(FaceType.font(.caption, size: typeSize))
                .foregroundStyle(FaceInk.ink)
                .lineLimit(1)
            TextField(FaceCopy.namePlaceholder, text: $desk.draftName)
                .font(FaceType.font(.caption, size: typeSize))
                .foregroundStyle(FaceInk.ink)
                .padding(FaceSpace.inner)
                .frame(minHeight: FaceSpace.hit)
                .faceChip()
                .focused($focused, equals: .name)
                .textInputAutocapitalization(.words)
                .accessibilityLabel(FaceCopy.namePlaceholder)
            TextField(FaceCopy.amountPlaceholder, text: amountBinding)
                .font(FaceType.font(.caption, size: typeSize))
                .foregroundStyle(FaceInk.ink)
                .keyboardType(.decimalPad)
                .padding(FaceSpace.inner)
                .frame(minHeight: FaceSpace.hit)
                .faceChip()
                .focused($focused, equals: .amount)
                .accessibilityLabel(FaceCopy.amountPlaceholder)
            Picker(FaceCopy.periodTitle, selection: $desk.draftPeriod) {
                ForEach(LotPeriod.allCases, id: \.self) { period in
                    Text(FaceCopy.periodWord(period)).tag(period)
                }
            }
            .pickerStyle(.menu)
            .font(FaceType.font(.caption, size: typeSize))
            .tint(FaceInk.ink)
            .frame(minHeight: FaceSpace.hit)
            .accessibilityLabel(FaceCopy.periodTitle)
            DatePicker(
                FaceCopy.chargeTitle,
                selection: $desk.draftCharge,
                displayedComponents: .date
            )
            .font(FaceType.font(.caption, size: typeSize))
            .tint(FaceInk.accent)
            .frame(minHeight: FaceSpace.hit)
            HStack(spacing: FaceSpace.inner) {
                Button(FaceCopy.cancel) {
                    focused = nil
                    desk.cancelCompose()
                }
                .buttonStyle(FaceQuietStyle(step: .caption))
                Button(FaceCopy.saveLot) {
                    focused = nil
                    Task { await desk.addDraft() }
                }
                .buttonStyle(FaceVerbStyle(emphasized: true, isLoading: desk.addBusy, step: .caption))
                .disabled(desk.addBusy || !canSave)
            }
        }
        .padding(FaceSpace.card)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: FaceRadius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: FaceRadius.card, style: .continuous)
                .stroke(FaceInk.muted.opacity(0.35), lineWidth: FacePaint.hairline)
        )
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button(FaceCopy.done) { focused = nil }
                    .font(FaceType.font(.caption, size: typeSize))
                    .foregroundStyle(FaceInk.ink)
            }
        }
    }

    private var canSave: Bool {
        !desk.draftName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && FaceFigures.parseAmount(desk.draftAmountText) != nil
    }

    private var amountBinding: Binding<String> {
        Binding(
            get: { desk.draftAmountText },
            set: { next in
                if FaceFigures.allowsAmountDraft(next) {
                    desk.draftAmountText = next
                }
            }
        )
    }
}

/// Role: Lot. Rim add chip. Same snapshot identity as the composer.
struct LotAddChip: View {
    var action: () -> Void
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: FaceSpace.step(1)) {
                Image(systemName: "plus")
                    .font(FaceType.font(.caption, size: typeSize))
                    .foregroundStyle(FaceInk.ink)
                Text(FaceCopy.addChip)
                    .font(FaceType.font(.caption, size: typeSize))
                    .foregroundStyle(FaceInk.ink)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(FaceQuietStyle(step: .caption, compact: true))
        .accessibilityLabel(FaceCopy.addLot)
    }
}
