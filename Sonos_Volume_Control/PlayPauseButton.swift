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
                self.setAccessibilityLabel(NSLocalizedString("Play", comment: "AccessibilityLabel"))
            case .pause:
                self.image = #imageLiteral(resourceName: "ic_pause")
                self.setAccessibilityLabel(NSLocalizedString("Pause", comment: "AccessibilityLabel"))
            case .stop:
                self.image = #imageLiteral(resourceName: "ic_stop")
                self.setAccessibilityLabel(NSLocalizedString("Stop", comment: "AccessibilityLabel"))
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
