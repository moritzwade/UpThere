import SwiftUI

/// Settings view for configuring app preferences
struct SettingsView: View {
    @Bindable var settings: AppSettings
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                searchRadiusSection
                refreshIntervalSection
                mapStyleSection
                unitsSection
                apiCredentialsSection
            }
            #if os(macOS)
            .formStyle(.grouped)
            #endif
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    // MARK: - Search Radius

    private var searchRadiusSection: some View {
        Section("Search Radius") {
            Picker("Radius", selection: $settings.searchRadius) {
                ForEach(SearchRadius.allCases) { radius in
                    Text(radius.displayName).tag(radius)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    // MARK: - Refresh Interval

    @ViewBuilder
    private var refreshIntervalSection: some View {
        Section("Auto-Refresh") {
            Picker("Interval", selection: $settings.refreshOption) {
                ForEach(RefreshIntervalOption.allCases) { option in
                    Text(option.displayName).tag(option)
                }
            }
            .pickerStyle(.menu)

            if settings.refreshOption == .custom {
                HStack {
                    Text("Custom interval")
                    Spacer()
                    TextField("Seconds", value: $settings.customRefreshSeconds, format: .number)
                        #if os(iOS)
                        .keyboardType(.numberPad)
                        #endif
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                    Text("s")
                        .foregroundColor(.secondary)
                }
            }

            if settings.refreshOption == .manual {
                Label("Tap the refresh button on the map to update manually", systemImage: "hand.tap")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    // MARK: - Map Style

    private var mapStyleSection: some View {
        Section("Map Style") {
            Picker("Style", selection: $settings.mapStyle) {
                ForEach(AppMapStyle.allCases) { style in
                    Text(style.displayName).tag(style)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    // MARK: - Unit Preferences

    private var unitsSection: some View {
        Section("Units") {
            Picker("Altitude", selection: $settings.altitudeUnit) {
                ForEach(AltitudeUnit.allCases) { unit in
                    Text(unit.displayName).tag(unit)
                }
            }
            Picker("Speed", selection: $settings.speedUnit) {
                ForEach(SpeedUnit.allCases) { unit in
                    Text(unit.displayName).tag(unit)
                }
            }
        }
    }

    // MARK: - API Credentials

    @ViewBuilder
    private var apiCredentialsSection: some View {
        Section("API Credentials") {
            TextField("Client ID", text: $settings.customClientId)
                #if os(iOS)
                .textInputAutocapitalization(.never)
                #endif
                .autocorrectionDisabled()

            SecureField("Client Secret", text: $settings.customClientSecret)

            VStack(alignment: .leading, spacing: 4) {
                Label("Overrides environment variables", systemImage: "info.circle")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Link("Get credentials at opensky-network.org",
                     destination: URL(string: "https://opensky-network.org/")!)
                    .font(.caption)
            }
            .padding(.top, 2)

            if settings.hasCustomCredentials {
                Button("Clear Credentials", role: .destructive) {
                    settings.customClientId = ""
                    settings.customClientSecret = ""
                }
            }
        }
    }
}
