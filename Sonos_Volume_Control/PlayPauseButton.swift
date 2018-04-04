//
//  CustomPopoverWindow.swift
//  Menu Bar Controller for Sonos
//
//  Created by Alexander Heinrich on 27.03.18.
//  Copyright © 2018 Sn0wfreeze Development UG. All rights reserved.
//

import Cocoa

class PlayPauseButton: NSButton {
    enum State {
        case play, pause, stop
    }
    
    var currentState: State = .play {
        didSet {
            switch currentState {
            case .play:
                self.image = #imageLiteral(resourceName: "ic_play_arrow")
                self.setAccessibilityLabel("Play")
            case .pause:
                self.image = #imageLiteral(resourceName: "ic_pause")
                self.setAccessibilityLabel("Pause")
            case .stop:
                self.image = #imageLiteral(resourceName: "ic_stop")
                self.setAccessibilityLabel("Stop")
            }
        }
    }
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}
