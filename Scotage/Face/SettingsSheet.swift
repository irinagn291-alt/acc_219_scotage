import SwiftUI

/// Role: Face. Settings sheet. ReviewScreen goals. Currency, Scot, local reminder, contact URL, reset. Empty, populated, error.
struct SettingsSheet: View {
    @Bindable var desk: FaceDesk
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @Environment(\.dynamicTypeSize) private var typeSize
    @FocusState private var focused: Field?
    @State private var confirmReset = false

    private enum Field: Hashable {
        case scot
    }

    var body: some View {
        FaceSheetHost {
            NavigationStack {
                Group {
                    if desk.fault == FaceCopy.startedEmpty {
                        FaceQuietPage(
                            art: FaceArt.emptyList,
                            headline: FaceCopy.settingsErrorHeadline,
                            line: FaceCopy.startedEmpty,
                            actionTitle: FaceCopy.retry,
                            step: .body
                        ) {
                            Task { await desk.retryLoad() }
                        }
                    } else {
                        form
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(FaceInk.background.ignoresSafeArea())
                .navigationTitle(FaceCopy.settingsTitle)
                .navigationBarTitleDisplayMode(.inline)
                .toolbarBackground(FaceInk.background, for: .navigationBar)
                .toolbarBackground(.visible, for: .navigationBar)
                .toolbar { closeToolbar }
                .confirmationDialog(
                    FaceCopy.resetConfirm,
                    isPresented: $confirmReset,
                    titleVisibility: .visible
                ) {
                    Button(FaceCopy.resetAction, role: .destructive) {
                        Task { await desk.resetAllData() }
                    }
                    Button(FaceCopy.cancel, role: .cancel) {}
                } message: {
                    Text(FaceCopy.resetMessage)
                }
            }
        }
    }

    private var form: some View {
        Form {
            if let fault = desk.fault {
                Section {
                    FaceNotice(message: fault) {
                        Task { await desk.retryLoad() }
                    }
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                }
            }
            if desk.settingsIsEmpty {
                Section {
                    VStack(alignment: .leading, spacing: FaceSpace.inner) {
                        Text(FaceCopy.settingsEmptyHeadline)
                            .font(FaceType.font(.headline, size: typeSize))
                            .foregroundStyle(FaceInk.ink)
                        Text(FaceCopy.settingsEmptyLine)
                            .font(FaceType.font(.caption, size: typeSize))
                            .foregroundStyle(FaceInk.muted)
                        Button(FaceCopy.insightsEmptyAction) {
                            dismiss()
                        }
                        .buttonStyle(FaceVerbStyle(emphasized: true, step: .body))
                    }
                    .padding(FaceSpace.card)
                    .faceSurface()
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                }
            }
            Section {
                Picker(FaceCopy.currencyTitle, selection: currencyBinding) {
                    ForEach(currencyCodes, id: \.self) { code in
                        Text(code).tag(code)
                    }
                }
                .font(FaceType.font(.body, size: typeSize))
                .tint(FaceInk.ink)
                .frame(minHeight: FaceSpace.hit)
                HStack(alignment: .center, spacing: FaceSpace.inner) {
                    Text(FaceCopy.scotTitle)
                        .font(FaceType.font(.body, size: typeSize))
                        .foregroundStyle(FaceInk.ink)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    TextField(FaceCopy.scotTitle, text: scotBinding)
                        .font(FaceType.font(.body, size: typeSize).monospacedDigit())
                        .foregroundStyle(FaceInk.ink)
                        .multilineTextAlignment(.trailing)
                        .keyboardType(.decimalPad)
                        .focused($focused, equals: .scot)
                        .frame(minWidth: FaceSpace.hit * 2, minHeight: FaceSpace.hit)
                        .accessibilityLabel(FaceCopy.scotTitle)
                        .onChange(of: focused) { _, next in
                            if next != .scot {
                                Task { await desk.commitScot() }
                            }
                        }
                }
                .frame(minHeight: FaceSpace.hit)
                .accessibilityElement(children: .contain)
                Toggle(FaceCopy.reminderTitle, isOn: reminderOn)
                    .font(FaceType.font(.body, size: typeSize))
                    .tint(FaceInk.accent)
                    .frame(minHeight: FaceSpace.hit)
                if desk.face.reminder.isOn {
                    DatePicker(
                        FaceCopy.reminderTime,
                        selection: reminderDate,
                        displayedComponents: .hourAndMinute
                    )
                    .font(FaceType.font(.body, size: typeSize))
                    .tint(FaceInk.accent)
                    .frame(minHeight: FaceSpace.hit)
                }
            }
            .listRowBackground(FaceInk.surface)
            Section {
                Button {
                    openURL(FaceCourier.contactURL)
                } label: {
                    VStack(alignment: .leading, spacing: FaceSpace.inner) {
                        Text(FaceCopy.contactTitle)
                            .font(FaceType.font(.headline, size: typeSize))
                            .foregroundStyle(FaceInk.ink)
                        Text(FaceCopy.contactDetail)
                            .font(FaceType.font(.caption, size: typeSize))
                            .foregroundStyle(FaceInk.muted)
                    }
                    .frame(maxWidth: .infinity, minHeight: FaceSpace.hit, alignment: .leading)
                    .contentShape(Rectangle())
                }
                .buttonStyle(FaceQuietStyle(step: .headline))
                .accessibilityLabel(FaceCopy.contactTitle)
            }
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
            Section {
                Button(FaceCopy.openTwist) {
                    desk.presentTwist()
                }
                .buttonStyle(FaceQuietStyle(step: .body))
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
                Button(FaceCopy.replayOnboarding) {
                    desk.replayOnboarding()
                }
                .buttonStyle(FaceQuietStyle(step: .body))
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
                Button(FaceCopy.resetTitle) {
                    confirmReset = true
                }
                .buttonStyle(FaceQuietStyle(destructive: true, step: .body))
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            }
        }
        .scrollContentBackground(.hidden)
        .scrollDismissesKeyboard(.interactively)
        .background(FaceInk.background)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button(FaceCopy.done) {
                    focused = nil
                    Task { await desk.commitScot() }
                }
                .font(FaceType.font(.body, size: typeSize))
                .foregroundStyle(FaceInk.ink)
            }
        }
    }

    private var currencyCodes: [String] {
        var codes = FaceFigures.currencyCodes
        if !codes.contains(desk.face.currencyCode) {
            codes.insert(desk.face.currencyCode, at: 0)
        }
        return codes
    }

    private var currencyBinding: Binding<String> {
        Binding(
            get: { desk.face.currencyCode },
            set: { code in
                Task { await desk.setCurrency(code) }
            }
        )
    }

    private var scotBinding: Binding<String> {
        Binding(
            get: { desk.draftScotText },
            set: { next in
                if FaceFigures.allowsAmountDraft(next) {
                    desk.draftScotText = next
                }
            }
        )
    }

    private var reminderOn: Binding<Bool> {
        Binding(
            get: { desk.face.reminder.isOn },
            set: { on in
                var reminder = desk.face.reminder
                reminder.isOn = on
                Task { await desk.setReminder(reminder) }
            }
        )
    }

    private var reminderDate: Binding<Date> {
        Binding(
            get: {
                var parts = DateComponents()
                parts.hour = desk.face.reminder.hour
                parts.minute = desk.face.reminder.minute
                return Calendar.current.date(from: parts) ?? Date()
            },
            set: { date in
                let hour = Calendar.current.component(.hour, from: date)
                let minute = Calendar.current.component(.minute, from: date)
                Task {
                    await desk.setReminder(
                        FaceReminder(isOn: desk.face.reminder.isOn, hour: hour, minute: minute)
                    )
                }
            }
        )
    }

    @ToolbarContentBuilder
    private var closeToolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                focused = nil
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
