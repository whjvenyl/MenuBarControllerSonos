//
//  SonosDeviceInfo.swift
//  Menu Bar Controller for Sonos
//
//  Created by Alexander Heinrich on 24.03.18.
//  Copyright © 2018 Sn0wfreeze Development UG. All rights reserved.
//

import Foundation
import SWXMLHash

public struct SonosDeviceInfo {
    public let zoneName: String
    public let localUID: String
    
    init?(xml: XMLIndexer) {
        let zpInfo = xml["ZPSupportInfo"]["ZPInfo"]
        guard let zoneName =  zpInfo["ZoneName"].element?.text,
            let localUID = zpInfo["LocalUID"].element?.text else {return nil}
        self.localUID = localUID
        self.zoneName = zoneName
    }
}
