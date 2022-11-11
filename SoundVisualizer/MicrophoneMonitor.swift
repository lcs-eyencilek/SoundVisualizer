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
    private var audioSession: AVAudioSession = AVAudioSession.sharedInstance()
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
            startAudioSession()
        } catch {
            fatalError(error.localizedDescription)
        }
    }
    
    private func startMonitoring(_ repeats: Bool = true) {
        audioRecorder.isMeteringEnabled = true
        audioRecorder.record()
        
        // This timer is to update the meters
        timer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: repeats, block: { (timer) in
            self.audioRecorder.updateMeters()
            self.soundSamples[self.currentSample] = self.audioRecorder.averagePower(forChannel: 0) // .averagePower(forChannel: 0) gives you the buffer value at chanel 0, this value is set to soundSamples at index currentSample
            self.currentSample = (self.currentSample + 1) % self.numberOfSamples // Set the new index value for currentSample
            print(self.audioRecorder)
            //let equalizer = AVAudioUnitEQ(audioComponentDescription: AudioComponentDescription())
            //print(equalizer.bands.first!.frequency)
        })
    }
    
    // MARK: Start - Stop Audio Sessions to Listen for Frequency
    func startAudioSession() {
        do {
            self.setupAudioSession()
            
            try self.audioSession.setActive(true)
            
            // Create a timer to print the data
            timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { (timer) in
                print(self.audioSession.sampleRate)
            })
            
        } catch {
            print("Start Recording Error: \(error.localizedDescription)")
        }
    }
    
    func stopAudioSession() {
        do {
            try self.audioSession.setActive(false)
        } catch {
            print("Error: \(error.localizedDescription)")
        }
    }
    
    // MARK: Setup Parameters for Audio Session
    private func setupAudioSession() {
            
        guard audioSession.availableCategories.contains(.record) else {
            print("can't record! bailing.")
            return
        }
        
        do {
            try audioSession.setCategory(.record)
            
            // "Appropriate for applications that wish to minimize the effect of system-supplied signal processing for input and/or output audio signals."
            // NB: This turns off the high-pass filter that CoreAudio normally applies.
            try audioSession.setMode(AVAudioSession.Mode.measurement)
            
            try audioSession.setPreferredSampleRate(Double(44100.0))
            
            // This will have an impact on CPU usage. .01 gives 512 samples per frame on iPhone. (Probably .01 * 44100 rounded up.)
            // NB: This is considered a 'hint' and more often than not is just ignored.
            try audioSession.setPreferredIOBufferDuration(0.01)
            
            audioSession.requestRecordPermission { (granted) -> Void in
                if !granted {
                    print("*** record permission denied")
                }
            }
        } catch {
            print("*** audioSession error: \(error)")
        }
    }
    
    
    deinit {
        timer?.invalidate()
        audioRecorder.stop()
    }
    
}
