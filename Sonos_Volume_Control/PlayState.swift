//
//  PlayState.swift
//  Sonos_Volume_Control
//
//  Created by Alexander Heinrich on 15.03.18.
//  Copyright © 2018 Sn0wfreeze Development UG. All rights reserved.
//

import Cocoa

public enum PlayState: String {
    case error = "ERROR"
    case stopped = "STOPPED"
    case playing = "PLAYING"
    case paused = "PAUSED_PLAYBACK"
    case transitioning = "TRANSITIONING"
    case notSet = "NOTSET"
}
