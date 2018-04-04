//
//  SonosTrackInfo.swift
//  Sonos_Volume_Control
//
//  Created by Alexander Heinrich on 30.03.18.
//  Copyright © 2018 Sn0wfreeze Development UG. All rights reserved.
//

import Foundation
import SWXMLHash

 public struct SonosTrackInfo {
    public let title: String
    public let album: String
    public let artist: String
    public let streamContent: String?
    public private(set) var playMedium: String?
    public private(set) var isPlayingRadio = false
    
    public private(set) var containsErrors = false
    
    init(xml: XMLIndexer) {
        title = xml["dc:title"].element?.text ?? "Unknown Title"
        album = xml["upnp:album"].element?.text ?? "Unknown Album"
        artist = xml["dc:creator"].element?.text ?? "Unkown Artist"
        streamContent = xml["r:streamContent"].element?.text
        
        if title == "Unknown Title" || album == "Unknown Album" || artist == "Unkown Artist" {
            containsErrors = true
        }
        
        if let protocolInfo = xml["res"].element?.attribute(by: "protocolInfo")?.text {
            isPlayingRadio = protocolInfo.contains("radio") && streamContent != nil
        }
    }
    
    func trackText() -> String {
        if containsErrors,
            let streamContent = self.streamContent {
            return streamContent
        }else if containsErrors {
            return ""
        }
        
        return "\(title) - \(artist)"
    }
    
    var description: String {
        return "\(title) - \(artist) - \(album) - \(streamContent ?? "No stream content")"
    }
}
