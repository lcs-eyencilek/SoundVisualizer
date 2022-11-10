//
//  ContentView.swift
//  SoundVisualizer
//
//  Created by Efe Yencilek on 2022-11-09.
//

import SwiftUI

let numberOfSamples: Int = 10

struct BarView: View {
   // 1
    var value: CGFloat

    var body: some View {
        ZStack {
           // 2
            RoundedRectangle(cornerRadius: 20)
                .fill(LinearGradient(gradient: Gradient(colors: [.purple, .blue]),
                                     startPoint: .top,
                                     endPoint: .bottom))
                // 3
                .frame(width: (UIScreen.main.bounds.width - CGFloat(numberOfSamples) * 4) / CGFloat(numberOfSamples), height: value)
        }
    }
}

struct ContentView: View {
    
    @State var active: Bool = false
    
    // Initializing Monitor w/ Number of Samples
    @ObservedObject private var mic = MicrophoneMonitor(numberOfSamples: numberOfSamples/*, toggler: $active, stopAfterFirst: true*/)
    
    // Converts sound samples into height for the bar
    private func normalizeSoundLevel(level: Float) -> CGFloat {
        let level = max(0.2, CGFloat(level) + 50) / 2 // between 0.1 and 25
        
        return CGFloat(level * (300 / 25)) // scaled to max at 300 (our height of our bar)
    }
    
    var body: some View {
        VStack {
            
            HStack(spacing: 4) {
                    // 4
                ForEach(mic.soundSamples, id: \.self) { level in
                    BarView(value: active ? self.normalizeSoundLevel(level: level) : 1)
                }
            }
            .frame(height: 300, alignment: .center)
            .border(.blue)
            
            Button(active ? "Stop" : "Start") {
                active.toggle()
            }
            .padding(.vertical, 25)
        }
    }
}
