//
//  SonosController.swift
//  Sonos_Volume_Control
//
//  Created by Alexander Heinrich on 08.04.18.
//  Copyright © 2018 Sn0wfreeze Development UG. All rights reserved.
//

import Cocoa
import SWXMLHash


public protocol SonosControllerDelegate {
    func didUpdateSpeakers()
    func didUpdateGroups()
}

public class SonosController {
    static let shared = SonosController.init()
    public private(set) var sonosSystems = [SonosDevice]()
    public private(set) var sonosGroups: [String : SonosSpeakerGroup] = [:]
    var lastDiscoveryDeviceList = [SonosDevice]()
    
    private let discovery: SSDPDiscovery = SSDPDiscovery.defaultDiscovery
    fileprivate var session: SSDPDiscoverySession?
    
    public var delegate: SonosControllerDelegate?
    
    var activeGroup: SonosSpeakerGroup? {
        return self.sonosGroups.values.first(where: {$0.isActive})
    }
    
    init() {
        //Show Demo only in demo target
        if (Bundle.main.object(forInfoDictionaryKey: "CFBundleIdentifier") as? String) == "de.sn0wfreeze.Sonos-Volume-Control-Demo" {
            self.showDemo()
        }
    }
    
    //MARK: - Updating Sonos Players
    /**
     Add a device to the list of devices
     
     - Parameters:
     - sonos: The Sonos Device which was found and should be added
     */
    func addDeviceToList(sonos: SonosDevice) {
        guard sonosSystems.contains(sonos) == false else {return}
        
//        if let stereoPartner = sonosSystems.first(where: {$0.roomName == sonos.roomName && $0.udn != sonos.udn}) {
//            if let gId = stereoPartner.groupState?.groupID,
//                gId.isEmpty == false {
//                //Stereo partner is the controller
//                stereoPartner.isInStereoSetup = true
//            }else if let idx = sonosSystems.index(of: stereoPartner) {
//                self.sonosSystems.remove(at: idx)
//                //This is the stereo controller
//                sonos.isInStereoSetup = true
//                self.sonosSystems.append(sonos)
//            }
//        }else {
//            //New sonos system. Add it to the list
//            self.sonosSystems.append(sonos)
//        }
        
        //New sonos system. Add it to the list
        self.sonosSystems.append(sonos)
        
        self.detectStereoPairs()
        self.sortSpeakers()
        self.delegate?.didUpdateSpeakers()
    }
    
    
    /// Detects all stereo pairs in the current device lists and removes the uuncontrollable speaker
    func detectStereoPairs() {
        var stereoPairs = Set<SonosStereoPair>()
        for sonos in self.sonosSystems {
            //Find stereo pair
            let pair = self.sonosSystems.filter({$0.roomName == sonos.roomName})
            if pair.count == 2,
                let sPair = SonosStereoPair(s1: pair.first!, s2: pair.last!) {
                stereoPairs.insert(sPair)
            }
        }
        
        //Remove the other speaker from the list of Stereo Pair speakers
        for pair in stereoPairs {
            guard let idx = self.sonosSystems.index(of: pair.otherSpeaker) else {continue}
            self.sonosSystems.remove(at: idx)
            pair.controller.isInStereoSetup = true
        }
    }
    
    /**
     Remove old devices which have not been discovered in the last discovery session
     */
    func removeOldDevices() {
        //Remove undiscovered devices
        //All devices which haven't been found on last discovery
        let undiscoveredDevices = self.sonosSystems.filter({self.lastDiscoveryDeviceList.contains($0) == false})
        for sonos in undiscoveredDevices {
            //Remove speaker from group
            if let gId  = sonos.groupState?.groupID {
                let deviceGroup = self.sonosGroups[gId]
                deviceGroup?.remove(sonos: sonos)
            }
        }
        
        self.sonosSystems = Array(self.lastDiscoveryDeviceList)
        self.detectStereoPairs()
        
        for group in self.sonosGroups.values {
            if group.speakers.count == 0 {
                //Remove it
                self.sonosGroups.removeValue(forKey: group.groupID)
            }
        }
        
        self.delegate?.didUpdateSpeakers()
    }
    
    /**
     Update the groups controllers
     
     - Parameters:
     - sonos: The Sonos speaker which should be added to the group
     */
    func updateGroups(sonos: SonosDevice) {
        guard let gId = sonos.groupState?.groupID else {return}
        
        if let group = self.sonosGroups[gId] {
            group.addSpeaker(sonos)
        }else if let group = SonosSpeakerGroup(groupID: gId,firstSpeaker: sonos) {
            self.sonosGroups[gId] = group
        }
        
        //Remove empty groups
        let containedInGroups = Array(self.sonosGroups.values.filter({$0.speakers.contains(sonos)}))
        for group in containedInGroups {
            //Check where speaker has moved to
            group.removeIfGroupChanged(sonos)
            if group.speakers.count == 0 {
                //Remove group
                self.sonosGroups.removeValue(forKey: group.groupID)
            }
        }
        
        self.updateGroupSpeakers()
        self.delegate?.didUpdateGroups()
        
    }
    
    /// Update the groups so all speakers will be added to the correct group
    func updateGroupSpeakers() {
        //The systems will be iterated and added to the correct group
        for sonos in self.sonosSystems {
            guard let gId = sonos.groupState?.groupID,
                let group = self.sonosGroups[gId] else {continue}
            //Check if the group contains the speaker already
            if group.speakers.contains(sonos) == false {
                group.addSpeaker(sonos)
            }
        }
    }
    
    /**
     Found a duplicate sonos. Check if the IP address has changed
     
     - Parameters:
     - idx: Index at which the equal sonos is placed in sCntrl.sonosSystems
     - sonos: The newly discovered sonos
     */
    func replaceSonos(atIndex idx: Int, withSonos sonos: SonosDevice) {
        let eqSonos = sonosSystems[idx]
        if eqSonos.ip != sonos.ip {
            //Ip address changes
            sonosSystems.remove(at: idx)
            sonosSystems.insert(sonos, at: idx)
            sonos.active = eqSonos.active
        }
    }
    

    func showDemo() {
        self.stopDiscovery()
        
        let t1 = SonosDevice(roomName: "Bedroom_3", deviceName: "PLAY:3", url: URL(string:"http://192.168.178.91")!, ip: "192.168.178.91", udn: "some-udn-1", deviceInfo: SonosDeviceInfo(zoneName: "Bedroom_3+1", localUID: "01"), groupState: SonosGroupState(name: "Bedroom", groupID: "01", deviceIds: ["01", "02"]))
        t1.playState = .playing
        self.addDeviceToList(sonos: t1)
        self.updateGroups(sonos: t1)
        
        let t2 = SonosDevice(roomName: "Bedroom_1", deviceName: "One", url: URL(string:"http://192.168.178.92")!, ip: "192.168.178.92", udn: "some-udn-2", deviceInfo:SonosDeviceInfo(zoneName: "Bedroom_3+1", localUID: "02"), groupState:  SonosGroupState(name: "Bedroom", groupID: "01", deviceIds: ["01", "02"]))
        t2.playState = .playing
        self.addDeviceToList(sonos: t2)
        self.updateGroups(sonos: t2)
        
        let t3 = SonosDevice(roomName: "Kitchen", deviceName: "PLAY:1", url: URL(string:"http://192.168.178.93")!, ip: "192.168.178.93", udn: "some-udn-3",
                             deviceInfo: SonosDeviceInfo(zoneName: "Kitchen", localUID: "03"), groupState: SonosGroupState(name: "Kitchen", groupID: "03", deviceIds: ["03"]))
        t3.playState = .paused
        self.addDeviceToList(sonos: t3)
        self.updateGroups(sonos: t3)
        
        let t4 = SonosDevice(roomName: "Living room", deviceName: "PLAY:5", url: URL(string:"http://192.168.178.94")!, ip: "192.168.178.94", udn: "some-udn-4",
                             deviceInfo: SonosDeviceInfo(zoneName: "Living room", localUID: "04"),
                             groupState: SonosGroupState(name: "Living room", groupID: "04", deviceIds: ["04", "05"]))
        t4.playState = .paused
        self.addDeviceToList(sonos: t4)
        self.updateGroups(sonos: t4)
        
        //        let t5 = SonosController(roomName: "Living room_2", deviceName: "PLAY:5", url: URL(string:"http://192.168.178.95")!, ip: "192.168.178.95", udn: "some-udn-5")
        //        t5.playState = .paused
        //        t5.deviceInfo = SonosDeviceInfo(zoneName: "Living room", localUID: "05")
        //        t5.groupState = sCntrl.sonosGroupstate(name: "Living room", groupID: "04", deviceIds: ["04", "05"])
        //        self.addDeviceToList(sonos: t5)
        //        self.updateGroups(sonos: t5)
    }
}

extension SonosController: SSDPDiscoveryDelegate {
    
    func searchForDevices() {
        self.stopDiscovery()
        self.lastDiscoveryDeviceList.removeAll()
        
        print("Searching devices")
        // Create the request for Sonos ZonePlayer devices
        let zonePlayerTarget = SSDPSearchTarget.deviceType(schema: SSDPSearchTarget.upnpOrgSchema, deviceType: "ZonePlayer", version: 1)
        let request = SSDPMSearchRequest(delegate: self, searchTarget: zonePlayerTarget)
        
        // Start a discovery session for the request and timeout after 10 seconds of searching.
        self.session = try! discovery.startDiscovery(request: request, timeout: 10.0)
    }
    
    func stopDiscovery() {
        self.session?.close()
        self.session = nil
    }
    
    public func discoveredDevice(response: SSDPMSearchResponse, session: SSDPDiscoverySession) {
        //        print("Found device \(response)")
        retrieveDeviceInfo(response: response)
    }
    
    func retrieveDeviceInfo(response: SSDPMSearchResponse) {
        URLSession.init(configuration: URLSessionConfiguration.default).dataTask(with: response.location) { (data, resp, err) in
            if let data = data {
                let xml =  SWXMLHash.parse(data)
                let udn = xml["root"]["device"]["UDN"].element?.text
                //Check if device is already available
                if let sonos = self.sonosSystems.first(where: {$0.udn == udn}) {
                    //Update the device
                    sonos.update(withXML: xml, url: response.location)
                    sonos.updateAll {
                        self.updateGroups(sonos: sonos)
                    }
                    self.lastDiscoveryDeviceList.append(sonos)
                }else {
                    let sonosDevice = SonosDevice(xml: xml, url: response.location, { (sonos) in
                        self.updateGroups(sonos: sonos)
                        
                        DispatchQueue.main.async {
                            self.addDeviceToList(sonos: sonos)
                        }
                    })
                    self.lastDiscoveryDeviceList.append(sonosDevice)
                }
            }
            }.resume()
    }
    
    func sortSpeakers() {
        //Sort the sonos systems
        self.sonosSystems.sort { (lhs, rhs) -> Bool in
            return  lhs.readableName < rhs.readableName
        }
    }
    
    public func discoveredService(response: SSDPMSearchResponse, session: SSDPDiscoverySession) {
        print("Found service \(response)")
    }
    
    public func closedSession(_ session: SSDPDiscoverySession) {
        print("Session closed")
        self.removeOldDevices()
    }
}

