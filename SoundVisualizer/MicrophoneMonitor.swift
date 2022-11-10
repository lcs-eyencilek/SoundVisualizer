//
//  MicrophoneMonitor.swift
//  SoundVisualizer
//
//  Created by Efe Yencilek on 2022-11-09.
//

import Foundation
import AVFoundation // Audio Vision Foundation Library Helps us Monitor Microphone
import SwiftUI

class MicrophoneMonitor: ObservableObject {
    
    // MARK: Properties
    private var audioRecorder: AVAudioRecorder
    private var timer: Timer?
    
    private var currentSample: Int
    private let numberOfSamples: Int
    
    // Sample Numbers
    @Published public var soundSamples: [Float] // We collect the sound buffer produced at an instance
    
    // Properties to stop the cycle after one iteration
    //var active: Binding<Bool>
    //var shouldStopAfterFirstRecording: Bool
    
    init(numberOfSamples: Int/*, toggler: Binding<Bool>, stopAfterFirst: Bool*/) {
        //self.active = toggler // Set binding value initially
        //self.shouldStopAfterFirstRecording = stopAfterFirst
        
        self.numberOfSamples = numberOfSamples // In production check this is > 0.
        self.soundSamples = [Float](repeating: .zero, count: numberOfSamples)
        self.currentSample = 0
        
        
        let audioSession = AVAudioSession.sharedInstance()
        if audioSession.recordPermission != .granted {
            audioSession.requestRecordPermission { (isGranted) in
                if !isGranted {
                    fatalError("You must allow audio recording for this demo to work")
                }
            }
        }
             
        let url = URL(fileURLWithPath: "/dev/null", isDirectory: true)
        let recorderSettings: [String:Any] = [
            AVFormatIDKey: NSNumber(value: kAudioFormatAppleLossless),
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.min.rawValue
        ]
                
        do {
            audioRecorder = try AVAudioRecorder(url: url, settings: recorderSettings)
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [])
            startMonitoring()
        } catch {
            fatalError(error.localizedDescription)
        }
    }
    
    private func startMonitoring(_ repeats: Bool = true) {
        audioRecorder.isMeteringEnabled = true
        audioRecorder.record()
        timer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: repeats, block: { (timer) in
            self.audioRecorder.updateMeters()
            self.soundSamples[self.currentSample] = self.audioRecorder.averagePower(forChannel: 0)
            self.currentSample = (self.currentSample + 1) % self.numberOfSamples
        })
        
        //print(audioRecorder.settings)
    }
    
    deinit {
        timer?.invalidate()
        audioRecorder.stop()
    }
    
}
