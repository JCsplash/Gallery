//
//  AudioUtils.swift
//  FlairTime
//
//  Created by Jack Chen on 9/30/17.
//  Copyright © 2017 Flair Time LLC. All rights reserved.
//

import AVFoundation
import AVKit

class AudioUtils {
    static func switchToAmbient(setActive: Bool){
        switch setActive {
        case true:
            do {
                try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryAmbient)
                try AVAudioSession.sharedInstance().setActive(true)
            } catch {
                print("some error")
            }
        case false:
            do {
                try AVAudioSession.sharedInstance().setActive(false, with: .notifyOthersOnDeactivation)
                try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryAmbient)
            } catch {
                print("some error")
            }
        }
    }
}
