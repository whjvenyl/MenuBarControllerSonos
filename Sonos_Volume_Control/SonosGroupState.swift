//
//  SonosGroupState.swift
//  Menu Bar Controller for Sonos
//
//  Created by Alexander Heinrich on 24.03.18.
//  Copyright © 2018 Sn0wfreeze Development UG. All rights reserved.
//

import Cocoa
import SWXMLHash

struct SonosGroupState {
    let name: String
    let groupID: String
    let deviceIds: [String]
    
    init?(xml: XMLIndexer) {
        let attributes = xml["s:Envelope"]["s:Body"]["u:GetZoneGroupAttributes"]
        self.name = attributes["CurrentZoneGroupName"].element?.text ?? "No name"
        guard let gId = attributes["CurrentZoneGroupID"].element?.text else {return nil}
        self.groupID = gId
        guard let deviceIdString = attributes["CurrentZonePlayerUUIDsInGroup"].element?.text else {return nil}
        self.deviceIds =  deviceIdString.split(separator: ",").map({String($0)})
    }
}
