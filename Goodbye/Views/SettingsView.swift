import SwiftUI

/// Rhythm, reminder time, suggestions, export. Nothing you ever have to open.
struct SettingsView: View {
    @Environment(Store.self) private var store
    @State private var exportURL: URL?

    var body: some View {
        @Bindable var store = store
        Form {
            Section {
                Picker("Rhythm", selection: $store.settings.rhythm) {
                    ForEach(Rhythm.allCases) { rhythm in
                        Text(rhythm.title).tag(rhythm)
                    }
                }
                DatePicker("Counting from", selection: $store.settings.startDate,
                           displayedComponents: .date)
            } footer: {
                Text("Due days are counted from this date. Changing it recolours History; nothing is lost.")
            }

            Section {
                Toggle("Nudge", isOn: reminderToggle)
                if store.settings.remindersOn {
                    DatePicker("Time", selection: reminderTime, displayedComponents: .hourAndMinute)
                }
            } footer: {
                Text("One a day, only while something is waiting.")
            }

            Section {
                Toggle("Suggestions", isOn: $store.settings.suggestionsOn)
            }

            Section {
                if let url = exportURL {
                    ShareLink("Export data (JSON)", item: url)
                }
                LabeledContent("Version", value: "0.1")
            }
        }
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
        .dailyWash(store.todayHue)
        .navigationTitle("Settings")
        .task {
            exportURL = try? store.exportURL()
        }
        .onChange(of: store.settings.rhythm) { _, _ in store.settingsChanged() }
        .onChange(of: store.settings.startDate) { _, _ in store.settingsChanged() }
        .onChange(of: store.settings.suggestionsOn) { _, _ in store.settingsChanged() }
    }

    /// Switching the reminder on asks the system for permission there and then, so the prompt
    /// lands on intent rather than at launch.
    private var reminderToggle: Binding<Bool> {
        Binding(
            get: { store.settings.remindersOn },
            set: { wants in
                if wants {
                    Task { await store.enableReminders() }
                } else {
                    store.updateSettings { $0.remindersOn = false }
                }
            }
        )
    }

    /// Hour and minute live as two ints; the picker wants a Date.
    private var reminderTime: Binding<Date> {
        Binding(
            get: {
                store.calendar.date(
                    bySettingHour: store.settings.reminderHour,
                    minute: store.settings.reminderMinute,
                    second: 0,
                    of: store.now
                ) ?? store.now
            },
            set: { newValue in
                let parts = store.calendar.dateComponents([.hour, .minute], from: newValue)
                store.updateSettings {
                    $0.reminderHour = parts.hour ?? 19
                    $0.reminderMinute = parts.minute ?? 0
                }
            }
        )
    }
}
