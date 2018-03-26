//
//  CustomScrolllView.swift
//  Menu Bar Controller for Sonos
//
//  Created by Alexander Heinrich on 21.03.18.
//  Copyright © 2018 Sn0wfreeze Development UG. All rights reserved.
//

import Cocoa

class CustomScrolllView: NSScrollView {
    var isScrollingEnabled = false

    override func draw(_ frame: NSRect) {
        super.draw(frame)
    }
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func scrollWheel(with event: NSEvent) {
        if isScrollingEnabled {
            super.scrollWheel(with: event)
        }
        //Scrolling disabled if false
    }
    
    override var isFlipped: Bool {
        return false
    }
    
    func scrollToTop() {
//        self.verticalScroller?.floatValue = 0.0
//        if self.contentView.isFlipped {
//            self.contentView.scroll(to: NSPoint(x: 0.0, y: 0.0))
//        }else {
//            self.contentView.scroll(to: NSPoint(x: 0.0, y: self.documentView!.frame.maxY - self.contentView.bounds.height))
//        }
        
        
        
    }
}
