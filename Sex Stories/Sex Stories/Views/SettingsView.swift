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
                    .foregroundStyle(scrapper.primaryColor)

                themedCard(title: "Appearance") {
                    VStack(alignment: .leading, spacing: 16) {
                        Picker("Theme", selection: $scrapper.selectedTheme) {
                            ForEach(AppTheme.allCases) { theme in
                                Text(theme.label).tag(theme)
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(scrapper.accentColor)
                        .foregroundStyle(scrapper.primaryColor)

                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text("Font Size")
                                Spacer()
                                Text("\(Int(scrapper.fontSize)) pt")
                            }
                            Slider(value: $scrapper.fontSize, in: 14...32, step: 1)
                                .tint(scrapper.accentColor)
                        }

                        Text("Theme and font size apply across the entire app, including the reader.")
                            .font(.footnote)
                            .foregroundStyle(scrapper.secondaryColor)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                themedCard(title: "Theme Preview") {
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
        .foregroundStyle(scrapper.primaryColor)
    }

    private func themedCard<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title)
                .font(.headline)
                .foregroundStyle(scrapper.primaryColor)
            content()
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(scrapper.primaryColor.opacity(scrapper.selectedTheme == .night ? 0.08 : 0.12))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(scrapper.primaryColor.opacity(0.12), lineWidth: 1)
        )
    }
}
