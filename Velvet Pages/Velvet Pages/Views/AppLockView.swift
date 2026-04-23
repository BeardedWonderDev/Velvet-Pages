//
//  AppLockView.swift
//  Velvet Pages
//

import SwiftUI

struct AppLockView: View {
    @EnvironmentObject var lockViewModel: AppLockViewModel

    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: "faceid")
                .font(.system(size: 54, weight: .semibold))
                .symbolRenderingMode(.hierarchical)

            Text("Locked")
                .font(.title.bold())

            Text("Use Face ID or Touch ID to unlock Velvet Pages.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            if let errorMessage = lockViewModel.errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.red)
                    .padding(.top, 4)
            }

            Button {
                Task { await lockViewModel.unlock() }
            } label: {
                Text(lockViewModel.isAuthenticating ? "Unlocking..." : "Unlock")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(lockViewModel.isAuthenticating)
            .padding(.top, 4)
        }
        .padding(24)
        .frame(maxWidth: 360)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.ultraThinMaterial)
    }
}
