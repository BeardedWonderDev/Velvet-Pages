//
//  AppProperties.swift
//  Consensual Connections
//
//  Created by BoiseITGuru on 4/11/23.
//

import Foundation

class AppProperties: ObservableObject {
    @Published var isLandscape: Bool
    @Published var isiPad: Bool
    @Published var isSplit: Bool
    @Published var isMaxSplit: Bool
    @Published var size: CGSize
    
    init(isLandscape: Bool, isiPad: Bool, isSplit: Bool, isMaxSplit: Bool, size: CGSize) {
        self.isLandscape = isLandscape
        self.isiPad = isiPad
        self.isSplit = isSplit
        self.isMaxSplit = isMaxSplit
        self.size = size
    }
}
