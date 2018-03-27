//
//  SonosSpeakerGroup.swift
//  Menu Bar Controller for Sonos
//
//  Created by Alexander Heinrich on 24.03.18.
//  Copyright © 2018 Sn0wfreeze Development UG. All rights reserved.
//

import Cocoa
import SWXMLHash

//TODO: Add delegate
class SonosSpeakerGroup: Hashable {
    var name: String!
    let groupID: String
    private var speakers: Set<SonosController> = Set()
    
    var isActive: Bool = false
    
    /// Get the group's controller
    var mainSpeaker: SonosController? {
        return speakers.first(where: {groupID.hasPrefix($0.deviceInfo?.localUID ?? "000")})
    }
    
    init(groupID: String, firstSpeaker: SonosController) {
        self.groupID = groupID
        self.addSpeaker(firstSpeaker)
    }
    
    func addSpeaker(_ sonos: SonosController) {
        guard sonos.groupState?.groupID == self.groupID else {return}
        self.speakers.insert(sonos)
        if let groupName = sonos.groupState?.name {
            self.name = groupName
        }
    }
    
    @objc func activateDeactivate(button: NSButton) {
        if button.state == .on {
            self.isActive = true
        }else if button.state == .off {
            self.isActive = false
        }
        
        //Update delegate
    }
    
    func setVolume(volume: Int){
        self.mainSpeaker?.setVolume(volume: volume)
    }
    
    func setMute(muted: Bool) {
        self.mainSpeaker?.setMute(muted: muted)
    }
    
    func play() {
        self.mainSpeaker?.play()
    }
    
    func pause() {
        self.mainSpeaker?.pause()
    }
    
    func next() {
        self.mainSpeaker?.next()
    }
    
    func previous() {
        self.mainSpeaker?.previous()
    }
    
    
    var hashValue: Int {
        return self.groupID.hashValue
    }
    
    static func ==(l:SonosSpeakerGroup, r:SonosSpeakerGroup) -> Bool {
        return l.groupID == r.groupID
    }
    
}
