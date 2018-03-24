//
//  SonosDeviceInfo.swift
//  Menu Bar Controller for Sonos
//
//  Created by Alexander Heinrich on 24.03.18.
//  Copyright © 2018 Sn0wfreeze Development UG. All rights reserved.
//

import Foundation
import SWXMLHash

struct SonosDeviceInfo {
    let zoneName: String
    let localUID: String
    
    init?(xml: XMLIndexer) {
        //TODO: Check XML Path
        guard let zoneName =  xml["ZoneName"].element?.text,
            let localUID = xml["LocalUID"].element?.text else {return nil}
        self.localUID = localUID
        self.zoneName = zoneName
    }
}
