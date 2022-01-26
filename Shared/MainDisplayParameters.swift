//
//  MainDisplayParameters.swift
//  MainDisplayParameters
//
//  Created by Jeff_Terry on 1/25/22.
//

import Foundation


class MainDisplayParameters: NSObject, ObservableObject {
    
    @MainActor @Published var insideData = [(xPoint: Double, yPoint: Double)]()
    @MainActor @Published var outsideData = [(xPoint: Double, yPoint: Double)]()
    @MainActor @Published var totalGuessesString = ""
    @MainActor @Published var guessesString = ""
    @MainActor @Published var heartString = ""
    @MainActor @Published var enableButton = true
    @MainActor @Published var totalGuesses :Int32 = 0
    @MainActor @Published var totalIntegral = 0.0
    @MainActor @Published var insideFraction = 0.0

}
