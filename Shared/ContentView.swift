//
//  ContentView.swift
//  Valentine's Day
//
//  Created by Jeff_Terry on 1/23/22.
//

import SwiftUI
import Foundation

struct ContentView: View {
    @State var pi = 0.0
    @State var totalGuesses :Int32 = 0
    @State var totalIntegral = 0.0
    @State var radius = 1.0
    @State var guessString = "23458"
    @State var guesses :Int32 = 0
    @State var maxPointsForPlot = 400001
    
    
    // Setup the GUI to monitor the data from the Monte Carlo Integral Calculator
    
    @ObservedObject var mainDisplayParameters = MainDisplayParameters()
    
    
    //Setup the GUI View
    var body: some View {
        HStack{
            
            VStack{
                
                VStack(alignment: .center) {
                    Text("Guesses")
                        .font(.callout)
                        .bold()
                    TextField("# Guesses", text: $guessString)
                        .padding()
                }
                .padding(.top, 5.0)
                
                VStack(alignment: .center) {
                    Text("Total Guesses")
                        .font(.callout)
                        .bold()
                    TextField("# Total Guesses", text: $mainDisplayParameters.totalGuessesString)
                        .padding()
                }
                
                VStack(alignment: .center) {
                    Text("Heart Integral")
                        .font(.callout)
                        .bold()
                    TextField("# Heart", text: $mainDisplayParameters.heartString)
                        .padding()
                }
                
                Button("Cycle Calculation", action: { self.calculateHeart()})
                .padding()
                .disabled(mainDisplayParameters.enableButton == false)
                
                Button("Clear", action: {self.clear()})
                    .padding(.bottom, 5.0)
                    .disabled(mainDisplayParameters.enableButton == false)
                
                if (!mainDisplayParameters.enableButton){
                    
                    ProgressView()
                }
                
                
            }
            .padding()
            
            //DrawingField
            
            
            drawingView(redLayer:$mainDisplayParameters.insideData, blueLayer: $mainDisplayParameters.outsideData)
                .padding()
                .aspectRatio(1, contentMode: .fit)
            // Stop the window shrinking to zero.
            Spacer()
            
        }
    }
    
    func calculateHeart() {
        
        guesses = Int32((guessString)) ?? 23458
        totalGuesses = mainDisplayParameters.totalGuesses
        
        // Spawn 1 thread per processor core
        let numberOfThreads = ProcessInfo.processInfo.processorCount
        
        
        Task{
            
            mainDisplayParameters.enableButton = false
           // await updateGUI(text: "Start time \(Date())\n")
            
            
            let heartResults = await withTaskGroup(of: (Int, (integralWithoutTotalGuesses: Double, insidePoints: [(xPoint: Double, yPoint: Double)], outsidePoints: [(xPoint: Double, yPoint: Double)])).self, /* this is the return from the taskGroup*/
                                                      returning: [(Int, (integralWithoutTotalGuesses: Double, insidePoints: [(xPoint: Double, yPoint: Double)], outsidePoints: [(xPoint: Double, yPoint: Double)]))].self, /* this is the return from the result collation */
                                                      body: { taskGroup in  /*This is the body of the task*/
                
                // We can use `taskGroup` to spawn child tasks here.
                
                
                for i in stride(from: 0, to: numberOfThreads, by: 1){
                    
                    taskGroup.addTask {
                        
                        
                        //Create a new instance of the ValentineHeart object so that each has it's own calculating function to avoid potential issues with reentrancy problem
                        
                        let valentinesHeart = await ValentineHeart.init(withData: true)
                        
                        valentinesHeart.guesses = await Int( guesses)

                        let singleResult = await valentinesHeart.calculateHeart()
                        
                        
                        
                        return (i, singleResult)  /* this is the return from the taskGroup*/
                        
                    }
                    
                    
                }
                
                // Collate the results of all child tasks
                var combinedTaskResults :[(Int, (integralWithoutTotalGuesses: Double, insidePoints: [(xPoint: Double, yPoint: Double)], outsidePoints: [(xPoint: Double, yPoint: Double)]))] = []
                for await result in taskGroup {
                    
                    combinedTaskResults.append(result)
                }
                
                return combinedTaskResults  /* this is the return from the result collation */
                
            })
            
            
            //Do whatever processing that you need with the returned results of all of the child tasks here.
            
            
            var localIntegral = 0.0
            var inside :[(xPoint: Double, yPoint: Double)] = []
            var outside :[(xPoint: Double, yPoint: Double)] = []
            
            for item in heartResults{
                
                localIntegral += item.1.integralWithoutTotalGuesses
                
                totalGuesses += guesses
                
                if totalGuesses <= maxPointsForPlot{
                    
                    inside.append(contentsOf: item.1.insidePoints)
                    
                    outside.append(contentsOf: item.1.outsidePoints)
                }
                
            }
            
            mainDisplayParameters.insideData+=inside
            mainDisplayParameters.outsideData+=outside
            mainDisplayParameters.insideFraction += localIntegral
            
            mainDisplayParameters.totalGuesses = totalGuesses
            
            
            mainDisplayParameters.totalIntegral =  mainDisplayParameters.insideFraction / Double(totalGuesses)
            
            mainDisplayParameters.totalGuessesString = "\(totalGuesses)"
            
            mainDisplayParameters.heartString = "\(mainDisplayParameters.totalIntegral)"
            
            
            mainDisplayParameters.enableButton = true
            
        }
        
        
    }
    
    func clear(){
        
        guessString = "23458"
        mainDisplayParameters.totalGuesses = 0
        mainDisplayParameters.totalIntegral = 0.0
        mainDisplayParameters.insideFraction = 0.0
        mainDisplayParameters.insideData = []
        mainDisplayParameters.outsideData = []
        mainDisplayParameters.totalGuessesString = ""
        mainDisplayParameters.guessesString = ""
        mainDisplayParameters.heartString = ""
        
        
    }
    
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
