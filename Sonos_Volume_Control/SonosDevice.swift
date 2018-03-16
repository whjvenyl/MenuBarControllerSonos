//
//  SonosDevice.swift
//  Sonos_Volume_Control
//
//  Created by Alexander Heinrich on 14.03.18.
//  Copyright © 2018 Sn0wfreeze Development UG. All rights reserved.
//

import Cocoa
import SWXMLHash

protocol SonosControllerDelegate {
    func didUpdateActiveState(forSonos sonos: SonosController, isActive: Bool)
}

class SonosController: Equatable {
    /// Name of the room
    var roomName: String
    /// Name of the device
    var deviceName: String
    /// URL where to find it
    var url: URL
    var ip: String
    var port: Int = 1400
    var udn:String
    var descriptionXML: XMLIndexer?
    var active: Bool = true
    var currentVolume = 0
    var playState = PlayState.notSet
    
    var delegate: SonosControllerDelegate?
    
    init(xml: XMLIndexer, url: URL) {
        let device = xml["root"]["device"]
        let displayName = device["displayName"].element?.text
        let roomName = device["roomName"].element?.text
        self.roomName = roomName ?? "unknown"
        self.deviceName = displayName ?? "unknown"
        self.url = url
        self.ip = url.host ?? "127.0.0.0"
        self.descriptionXML = xml
        self.udn = device["UDN"].element?.text ?? "no-id"
        self.updateCurrentVolume()
        self.getPlayState()
    }
    
    init(roomName:String, deviceName:String, url:URL, ip: String, udn: String) {
        self.roomName = roomName
        self.deviceName = deviceName
        self.url = url
        self.ip = ip
        self.udn = udn
    }
    
    var readableName:String {
        return "\(roomName) - \(deviceName)"
    }
    
    /**
     Set the volume of the Sonos device
     
     - Parameters:
     - volume: between 0 and 100
     */
    func setVolume(volume: Int){
        let command = SonosCommand(endpoint: .rendering_endpoint, action: .setVolume, service: .rendering_service)
        command.put(key: "InstanceID", value: "0")
        command.put(key: "Channel", value: "Master")
        command.put(key: "DesiredVolume", value: String(volume))
        command.execute(sonos: self)
    }
    
    func getVolume(_ completion:@escaping (_ volume: Int)->Void) {
        let command = SonosCommand(endpoint: .rendering_endpoint, action: .getVolume, service: .rendering_service)
        command.put(key: "InstanceID", value: "0")
        command.put(key: "Channel", value: "Master")
        
        command.execute(sonos: self, { data in
            guard let data = data else {return}
            let xml = SWXMLHash.parse(data)
            //Get the volume out of the xml
            if let volumeText = xml["s:Envelope"]["s:Body"]["u:GetVolumeResponse"]["CurrentVolume"].element?.text,
                let volume = Int(volumeText) {
                self.currentVolume = volume
            }
            DispatchQueue.main.async {completion(self.currentVolume)}
        })
    }
    
    func getPlayState(_ completion: ((_ state: PlayState)->Void)? = nil) {
        let command = SonosCommand(endpoint: .transport_endpoint, action: .getTransportInfo, service: .transport_service)
        command.put(key: "InstanceID", value: "0")
        command.execute(sonos: self) { (data) in
            guard let data = data else {return}
            let xml = SWXMLHash.parse(data)
            guard let playStateString = xml["s:Envelope"]["s:Body"]["u:GetTransportInfoResponse"]["CurrentTransportState"].element?.text else {return}
            self.playState = PlayState(rawValue: playStateString) ?? .notSet
            DispatchQueue.main.async {
              completion?(self.playState)
            }
        }
    }
    
    func play() {
        let command = SonosCommand(endpoint: .transport_endpoint, action: .play, service: .transport_service)
        command.put(key: "InstanceID", value: "0")
        command.put(key: "Speed", value: "1")
        command.execute(sonos: self)
        self.playState = .playing
    }
    
    func pause() {
        let command = SonosCommand(endpoint: .transport_endpoint, action: .pause, service: .transport_service)
        command.put(key: "InstanceID", value: "0")
        command.put(key: "Speed", value: "1")
        command.execute(sonos: self)
        self.playState = .paused
    }
    
    func next() {
        let command = SonosCommand(endpoint: .transport_endpoint, action: .next, service: .transport_service)
        command.put(key: "InstanceID", value: "0")
        command.put(key: "Speed", value: "1")
        command.execute(sonos: self)
    }
    
    func previous() {
        let command = SonosCommand(endpoint: .transport_endpoint, action: .prev, service: .transport_service)
        command.put(key: "InstanceID", value: "0")
        command.put(key: "Speed", value: "1")
        command.execute(sonos: self)
    }
    
    func updateCurrentVolume() {
        getVolume { (volume) in }
    }
    
    @objc func activateDeactivate(button: NSButton) {
        if button.state == .on {
            self.active = true
        }else if button.state == .off {
            self.active = false
        }
        
        self.delegate?.didUpdateActiveState(forSonos: self, isActive: self.active)
    }
    
    static func ==(l:SonosController, r:SonosController) -> Bool {
        return l.udn == r.udn
    }
}
