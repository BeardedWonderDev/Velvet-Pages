//
//  SettingsView.swift
//  Sex Stories
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var scrapper: ScrapperViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header

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

                        Text("Theme, font size, and reading rhythm apply across the entire app, including the reader.")
                            .font(.footnote)
                            .foregroundStyle(scrapper.secondaryColor)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                themedCard(title: "Theme Preview") {
                    VStack(alignment: .leading, spacing: 10) {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [scrapper.primaryColor, scrapper.primaryColor.opacity(0.72)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(height: 24)
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [scrapper.secondaryColor, scrapper.secondaryColor.opacity(0.72)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(height: 24)
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [scrapper.accentColor, scrapper.accentColor.opacity(0.72)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(height: 24)
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [scrapper.backgroundColor, scrapper.backgroundColor.opacity(0.72)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
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

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Settings")
                .font(.largeTitle.bold())
                .foregroundStyle(scrapper.primaryColor)
            Text("Adjust appearance and reading preferences.")
                .font(.callout)
                .foregroundStyle(scrapper.secondaryColor)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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
