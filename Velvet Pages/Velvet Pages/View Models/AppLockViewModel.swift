//
//  AppLockViewModel.swift
//  Velvet Pages
//

import Foundation
import LocalAuthentication
import SwiftUI

@MainActor
final class AppLockViewModel: ObservableObject {
    @Published var isLocked: Bool = false
    @Published var isAuthenticating: Bool = false
    @Published var errorMessage: String?

    // TODO: Re-enable optional Face ID / Touch ID locking with a verified lifecycle flow.
    private let biometricLockKey = "biometricLockEnabled"

    var isBiometricLockEnabled: Bool {
        false
    }

    func configureForLaunch() {
        isLocked = false
        errorMessage = nil
    }

    func lock() {
        isLocked = false
    }

    func unlock() async {
        isLocked = false
        errorMessage = nil
    }

    func shouldPromptOnBecomeActive(previousPhase: ScenePhase, newPhase: ScenePhase) -> Bool {
        false
    }
}
