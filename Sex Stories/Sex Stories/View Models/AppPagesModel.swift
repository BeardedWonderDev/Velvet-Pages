//
//  AppPagesModel.swift
//  Consensual Connections
//
//  Created by BoiseITGuru on 4/11/23.
//

import Foundation

enum AppPages: String, CaseIterable, Codable, Hashable {
    case home = "Home"
    case profile = "Default Profile"
    case partners = "Partners"
    case account = "Account"
    
    var image: String {
        switch self {
        case .home:
            return "house"
        case .profile:
            return "person.text.rectangle"
        case .partners:
            return "person.3.sequence"
        case .account:
            return "person.circle"
        }
    }
}
