//
//  SonosGroupState.swift
//  Menu Bar Controller for Sonos
//
//  Created by Alexander Heinrich on 24.03.18.
//  Copyright © 2018 Sn0wfreeze Development UG. All rights reserved.
//

import Cocoa
import SWXMLHash

public struct SonosGroupState {
    public let name: String
    public let groupID: String
    public let deviceIds: [String]
    
    init?(xml: XMLIndexer) {
        let attributes = xml["s:Envelope"]["s:Body"]["u:GetZoneGroupAttributesResponse"]
        self.name = attributes["CurrentZoneGroupName"].element?.text ?? "No name"
        guard let gId = attributes["CurrentZoneGroupID"].element?.text else {return nil}
        self.groupID = gId
        guard let deviceIdString = attributes["CurrentZonePlayerUUIDsInGroup"].element?.text else {return nil}
        self.deviceIds =  deviceIdString.split(separator: ",").map({String($0)})
    }
}
