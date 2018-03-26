//
//  CustomScrollClipView.swift
//  Menu Bar Controller for Sonos
//
//  Created by Alexander Heinrich on 26.03.18.
//  Copyright © 2018 Sn0wfreeze Development UG. All rights reserved.
//

import Cocoa

class CustomScrollClipView: NSClipView {

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
    }
    
    override var isFlipped: Bool {
        return true
    }
}
