//
//  ValentineHeart.swift
//  ValentineHeart
//
//  Created by Jeff_Terry on 1/23/22.
//

import Foundation
import SwiftUI

typealias extrapolatedDifferenceFunction = (_ x: Double) -> Double
typealias rootFinderFunctionAlias = (_ x: Double) -> Double

class ValentineHeart: NSObject, ObservableObject {
    
    var insideData = [(xPoint: Double, yPoint: Double)]()
    var outsideData = [(xPoint: Double, yPoint: Double)]()

    
    var heart = 0.0
    var guesses = 1
    var totalGuesses = 0
    var totalIntegral = 0.0
    var xConstant = 0.0
    
    var maxXPointInHeart = 0.0
    var minXPointInHeart = 0.0
    
    @MainActor init(withData data: Bool){
        
        super.init()
        
        insideData = []
        outsideData = []
        
        //Determine maximum and minimum value of x in the Heart
        
        let tPrimeFunction :[[Double]] = self.calculatetPrimeFunction(min: -1, max:61.0, step: 0.02)
        
        let maximumOfIndex:[Double] = rootFinder(functionData: tPrimeFunction, h: 1.0E-5, step: 0.02, function: calculateValueOftPrimeFunction)
        
        maxXPointInHeart = calculateValueOftFunction(x: maximumOfIndex[0])
        minXPointInHeart = -maxXPointInHeart
        
        //print(maxXPointInHeart)
        
    }



    /// calculate the value of Heart Integral
    ///
    /// - Calculates the Value of the Heart Integral using Monte Carlo Integration
    ///
    /// - Parameter
    ///
    /// - Returns: Tuple containing the integral value not corrected by the total guesses, the points inside of the heart, the points outside of the heart
    ///
    func calculateHeart() async -> (integralWithoutTotalGuesses: Double, insidePoints: [(xPoint: Double, yPoint: Double)], outsidePoints: [(xPoint: Double, yPoint: Double)]){
        
        let maxGuesses = Double(guesses)
        let boundingBoxCalculator = BoundingBox() ///Instantiates Class needed to calculate the area of the bounding box.
    
        let integral = await self.calculateHeartIntegral(maxX: 10.0, maxY: 19.0, minX: -10.0, minY: -1.0, maxGuesses: maxGuesses)
        
        
        totalIntegral = totalIntegral + integral
        totalGuesses = totalGuesses + guesses
        
       // await updateTotalGuessesString(text: "\(totalGuesses)")
        
        //totalGuessesString = "\(totalGuesses)"
        
        ///Calculates the value of the Heart Integral
        
        heart = (totalIntegral * boundingBoxCalculator.calculateSurfaceArea(numberOfSides: 2, lengthOfSide1: 2.0*10.0, lengthOfSide2: 2.0*10.0, lengthOfSide3: 0.0)) // / (Double(totalGuesses))
        
       // await updateHeartString(text: "\(heart)")
        
        //heartString = "\(heart)"
        
        return (integralWithoutTotalGuesses: heart, insidePoints: insideData, outsidePoints: outsideData)
        
    }

    /// calculateHeartIntegral
    ///
    /// calculates the Monte Carlo Integral of the Heart Function
    ///
    /// - Parameters:
    ///   - maxX: maximum of X range
    ///   - maxY: maximum of Y range
    ///   - minX: minimum of X range
    ///   - minY: minimum of Y range
    ///   - maxGuesses: number of Guesses to add
    /// - Returns: Number of Points In the Heart
    //                      2                   pi  *  t
    //  x  =   +/- 0.01( - t  + 40t + 1200) sin(---------)
    //                                             180
    //
    //                      2                   pi  *  t
    //  y  =  +/+  0.01( - t  + 40t + 1200) cos(---------)
    //                                             180
    //
    //   0  <= t <= 60
    //
    func calculateHeartIntegral(maxX: Double, maxY: Double, minX: Double, minY: Double, maxGuesses: Double) async -> Double {
        
        var numberOfGuesses = 0.0
        var pointsInHeart = 0.0
        var integral = 0.0
        var point = (xPoint: 0.0, yPoint: 0.0)
 //       var tHeartParameter = 60.0
        
        var yHeartMin = -1.0
        var yHeartMax = 11.0
        
        
        var newInsidePoints : [(xPoint: Double, yPoint: Double)] = []
        var newOutsidePoints : [(xPoint: Double, yPoint: Double)] = []
        
        
        while numberOfGuesses < maxGuesses {

            // Calculate 2 random values for the (x,y) point within the box
            // Determine if the point falls within the Heart Function
            
            point.xPoint = Double.random(in: minX...maxX)

            point.yPoint = Double.random(in: minY...maxY)

            switch point.xPoint {
                case let (x) where (x > maxXPointInHeart || x < minXPointInHeart):
                newOutsidePoints.append(point)
            default:

                //Convert x to t so we can calculate yMax and yMin
                if point.xPoint >= 0.0{
                    xConstant = point.xPoint
                }
                else{
                    
                    xConstant = -point.xPoint
                    
                }
                
                let tFunction :[[Double]] = self.calculatetFunction(min: -1, max:61.0, step: 0.02)
                let tValues = rootFinder(functionData: tFunction, h: 1.0E-5, step: 0.02, function: calculateValueOftFunction)
                
                if tValues.count == 2 {
                
                    yHeartMin = calculateyValues(x: tValues[1])
                    yHeartMax = calculateyValues(x: tValues[0])
                    
                }
                else  if (tValues.count == 1) {
                    
                    yHeartMax = calculateyValues(x: tValues[0])
                    yHeartMin = yHeartMax - yHeartMax.ulp
                    yHeartMax = yHeartMax + yHeartMax.ulp
                }
                else {
                    
                    print("error", tValues.count)
                    print(point.xPoint, point.yPoint)
                }

                if((point.yPoint >= yHeartMin) && (point.yPoint <= yHeartMax)){

                    newInsidePoints.append(point)
                    pointsInHeart += 1.0
                }
                else {

                    newOutsidePoints.append(point)
                }
              
            }

                numberOfGuesses += 1.0

        }
              
        integral = Double(pointsInHeart)
        
        //Append the points to the arrays needed for the displays
        //Don't attempt to draw more than 500,0001 points to keep the display updating speed reasonable.
        
        if (totalGuesses < 500001){
        
            var plotInsidePoints = newInsidePoints
            var plotOutsidePoints = newOutsidePoints
            
            if (newInsidePoints.count > 750001) {
                
                plotInsidePoints.removeSubrange(750001..<newInsidePoints.count)
            }
            
            if (newOutsidePoints.count > 750001){
                plotOutsidePoints.removeSubrange(750001..<newOutsidePoints.count)
                
            }
            
            updateData(insidePoints: plotInsidePoints, outsidePoints: plotOutsidePoints)
            
        }
        
        return integral
        }


    /// calculateyValues
    ///
    /// Calculates the y value of the Heart Function
    ///
    // Find roots of
    //               2                   pi  *  t
    //  +/- 0.01( - t  + 40t + 1200) sin(---------) - x = 0
    //                                      180
    //
    // Use t to calculate y
    //                      2                   pi  *  t
    //  y  =  +/+  0.01( - t  + 40t + 1200) cos(---------)
    //                                             180
    //
    //   0  <= t <= 60
    //
    ///
    /// - Parameter x: value of t at which to calculate the function
    /// - Returns: value of the y function at point t
    ///
    func calculateyValues(x: Double)-> (Double){
        
        let y = 0.01*(-pow(x, 2.0) + 40.0*x + 1200)*cos(Double.pi*x/180.0)
        
        return(y)
    }


    /// calculateValueOftFunction
    ///
    //                      2                   pi  *  t
    //  f(t) = +/- 0.01( - t  + 40t + 1200) sin(---------) - x = 0
    //                                              180
    //
    //   0  <= t <= 60
    //
    ///
    /// - Parameter x: t value
    /// - Returns: value of the t function at point t
    ///
    func calculateValueOftFunction(x: Double) -> (Double) {
            
            let value = 0.01*(-pow(x, 2.0) + 40.0*x + 1200)*sin(Double.pi*x/180.0) - xConstant
        
    //    print(x, value)
            
        return(value)

        }


    /// calculateExtrapolatedDifference
    ///
    /// Calculates the derivative of a function y(x) at the point x
    ///
    //
    //  Extapolated Difference Approximation of a Derivative
    //
    //
    //                        h              h               h              h
    //             8 *(y(x + ---)  -  y(x - ---))  - (y(x + ---)  -  y(x - ---))
    //  d                     4              4               2              2
    //  -- y(x) =  ----------------------------------------------------------
    //  dx                                  3h
    //
    ///
    /// - Parameters:
    ///   - functionToDifferentiate: function to be differentiated to calculate the value of y at each of the 4 points in the Extrapolated Difference method
    ///   - x: Position at which to calculate the derivative
    ///   - h: Extrapolated Difference h term
    /// - Returns: deriviative of the function
    func calculateExtrapolatedDifference(functionToDifferentiate: extrapolatedDifferenceFunction, x: Double, h: Double)-> (Double) {
        
        let extrapolatedDifferenceDerivativeNumerator = 8.0 * (functionToDifferentiate(x + (h/4.0)) - functionToDifferentiate(x - (h/4.0))) - (functionToDifferentiate(x + (h/2.0)) - functionToDifferentiate(x - (h/2.0)))
        
        let extrapolatedDifferenceDerivative = extrapolatedDifferenceDerivativeNumerator/(3.0*h)
        
    return(extrapolatedDifferenceDerivative)

    }
    
    /// calculateValueOftPrimeFunction
    ///
    /// Uses the Extrapolated Difference Method to calculate the individual points within the first derivative of the t Function
    ///
    /// - Parameter x: point at which to calculate (t)
    /// - Returns: value of the first derivative function at point t
    ///
    func calculateValueOftPrimeFunction(x: Double) -> (Double){
        
        let tPrimeFunction = calculateExtrapolatedDifference(functionToDifferentiate: calculateValueOftFunction, x: x, h: 1E-5)
        
        return(tPrimeFunction)
        
    }
    
    /// calculatetPrimeFunction
    ///
    /// Calculates the first derivative of the t Function
    ///
    /// - Parameters:
    ///   - min: minimum t
    ///   - max: maximum t
    ///   - step: step size
    /// - Returns: Two dimensional array of [t, tPrime]
    ///
    func calculatetPrimeFunction(min: Double, max: Double, step: Double) -> [[Double]] {
        
        var tPrimeFunctionValues :[[Double]] = []
        
        for index in stride(from: min, through: max, by: step){
            
            let tPrimeFunction = calculateValueOftPrimeFunction(x: index)
            
            tPrimeFunctionValues.append([index, tPrimeFunction])
            
        }
        
        return(tPrimeFunctionValues)
        
    }
    
    /// calculatetFunction
    ///
    /// Calculates the values of the t-function necessary to determine x and y in the Heart Function
    ///
    /// - Parameters:
    ///   - min: minimum t
    ///   - max: maximum t
    ///   - step: step size
    /// - Returns: Two dimensional array of [t, tFunction]
    ///
    func calculatetFunction(min: Double, max: Double, step: Double) -> [[Double]] {
        
        var tFunctionValues :[[Double]] = []
        
        for index in stride(from: min, through: max, by: step){
            
            let tFunction = calculateValueOftFunction(x: index)
            
            tFunctionValues.append([index, tFunction])
            
        }
        
        return(tFunctionValues)
        
    }
    
    
    /// rootFinder
    ///
    /// Uses the Newton-Raphson Method to find roots of an equation
    ///
    //                f(x )
    //                   0
    //  Delta x =  - ---------
    //                 df  |
    //                ---  |
    //                 dx  | x
    //                        0
    //
    ///
    /// - Parameters:
    ///   - functionData: Array of function data over which to find roots
    ///   - h: Extrapolated Difference h term
    ///   - step: step size
    ///   - function: Function used to calculate the exact values in the Extrapolated Difference
    /// - Returns: Roots of the function
    ///
    func rootFinder(functionData: [[Double]], h: Double, step: Double, function: rootFinderFunctionAlias) -> [Double]{
        
        var quickSearchResult :[Double] = []
        var finalRoots :[Double] = []
        
        var previousFunctionValue = functionData[0][1]
        
        for item in functionData{
            
            if(previousFunctionValue*item[1] <= 0){
                
                quickSearchResult.append(item[0])
            }
            
            previousFunctionValue = item[1]
            
        }
        
        
        for item in quickSearchResult{
            
            var x = item - 2.0*step
            
            //Newton-Raphson Search
            for _ in 0...10 {
                
                let newtonRaphsonNumerator = function(x)
                
                // Extrapolated Difference
                let newtonRaphsonDenominator = calculateExtrapolatedDifference(functionToDifferentiate: function, x: x, h: h)
                
                let deltaX = -newtonRaphsonNumerator/newtonRaphsonDenominator
                
                x = x + deltaX
                
                if abs(deltaX) <= x.ulp {
                    
                    break
                    
                }
            
            }
            
            finalRoots.append(x)
            
            
        }
        
        return(finalRoots)
        
    }
    
    /// updateData
    ///
    /// The function runs on the main thread so it can update the GUI
    ///
    /// - Parameters:
    ///   - insidePoints: points inside the circle of the given radius
    ///   - outsidePoints: points outside the circle of the given radius
    ///
    func updateData(insidePoints: [(xPoint: Double, yPoint: Double)] , outsidePoints: [(xPoint: Double, yPoint: Double)]){
        
        insideData.append(contentsOf: insidePoints)
        outsideData.append(contentsOf: outsidePoints)
    }
    

    

}



