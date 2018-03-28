//
//  TestExtensions.swift
//  Menu Bar Controller for Sonos
//
//  Created by Alexander Heinrich on 28.03.18.
//  Copyright © 2018 Sn0wfreeze Development UG. All rights reserved.
//

import Cocoa

extension SonosDeviceInfo {
    init(zoneName: String, localUID: String) {
        self.zoneName = zoneName
        self.localUID = localUID
    }
}

extension SonosGroupState {
    init(name: String, groupID: String, deviceIds: [String]) {
        self.groupID = groupID
        self.name = name
        self.deviceIds = deviceIds
    }
}


