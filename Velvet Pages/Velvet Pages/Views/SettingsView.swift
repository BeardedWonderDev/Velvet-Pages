//
//  SettingsView.swift
//  Sex Stories
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var scrapper: ScrapperViewModel
    @AppStorage("biometricLockEnabled") private var biometricLockEnabled = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                themedCard(title: "Security") {
                    Toggle(isOn: $biometricLockEnabled) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Require Face ID / Touch ID")
                            Text("Locks the app when it opens and when it returns to the foreground.")
                                .font(.footnote)
                                .foregroundStyle(scrapper.secondaryColor)
                        }
                    }
                    .tint(scrapper.accentColor)
                }

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
        .background(scrapper.surfaceColor.ignoresSafeArea())
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
                .fill(scrapper.mutedSurfaceColor)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(scrapper.borderColor, lineWidth: 1)
        )
    }
}
