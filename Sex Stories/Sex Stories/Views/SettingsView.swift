//
//  SettingsView.swift
//  Sex Stories
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var scrapper: ScrapperViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Settings")
                    .font(.largeTitle.bold())

                GroupBox("App Theme") {
                    VStack(alignment: .leading, spacing: 14) {
                        Picker("Theme", selection: $scrapper.selectedTheme) {
                            ForEach(AppTheme.allCases) { theme in
                                Text(themeLabel(theme)).tag(theme)
                            }
                        }
                        .pickerStyle(.menu)

                        Text("This theme now drives the reader, header, and sidebar.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                GroupBox("Theme Preview") {
                    VStack(alignment: .leading, spacing: 10) {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(scrapper.primaryColor)
                            .frame(height: 24)
                        RoundedRectangle(cornerRadius: 12)
                            .fill(scrapper.secondaryColor)
                            .frame(height: 24)
                        RoundedRectangle(cornerRadius: 12)
                            .fill(scrapper.accentColor)
                            .frame(height: 24)
                        RoundedRectangle(cornerRadius: 12)
                            .fill(scrapper.backgroundColor)
                            .frame(height: 24)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding()
        }
        .background(scrapper.backgroundColor.ignoresSafeArea())
        .foregroundStyle(scrapper.secondaryColor)
    }

    private func themeLabel(_ theme: AppTheme) -> String {
        switch theme {
        case .classicReadability: return "Classic Readability"
        case .modernMinimalist: return "Modern Minimalist"
        case .nightMode: return "Night Mode"
        case .natureInspired: return "Nature Inspired"
        }
    }
}
