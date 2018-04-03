//
//  UserDefaultsExtension.swift
//  Sonos_Volume_Control
//
//  Created by Alexander Heinrich on 02.04.18.
//  Copyright © 2018 Sn0wfreeze Development UG. All rights reserved.
//

import Cocoa

extension UserDefaults {
    var isLaunchAtLoginEnabled: Bool {
        get {
            return self.bool(forKey: "launchAtLogin")
        }
        set (v) {
            self.set(v, forKey: "launchAtLogin")
            self.synchronize()
        }
    }
}
