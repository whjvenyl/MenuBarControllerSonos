//
//  SonosSpeakerGroup.swift
//  Menu Bar Controller for Sonos
//
//  Created by Alexander Heinrich on 24.03.18.
//  Copyright © 2018 Sn0wfreeze Development UG. All rights reserved.
//

import Cocoa
import SWXMLHash

protocol SonosSpeakerGroupDelegate {
    func didChangeActiveState(group: SonosSpeakerGroup)
}

//TODO: Add delegate
class SonosSpeakerGroup: Hashable {
    var name: String
    let groupID: String
    private (set) var speakers: Set<SonosDevice> = Set()
    private var speakerOrder: [String]
    public var delegate: SonosSpeakerGroupDelegate?
    
    var isActive: Bool = false
    
    var trackInfo: SonosTrackInfo? {
        return self.mainSpeaker?.trackInfo
    }
    
    init?(groupID: String, firstSpeaker: SonosDevice) {
        guard let deviceIds = firstSpeaker.groupState?.deviceIds,
            let name = firstSpeaker.groupState?.name,
            groupID.isEmpty == false
            else {return nil}
        
        self.groupID = groupID
        self.speakerOrder = deviceIds
        self.name = name
        self.addSpeaker(firstSpeaker)
    }
    
    /// Get the group's controller
    private var mainSpeaker: SonosDevice? {
        if let main = speakers.first(where: {speakerOrder.first == $0.deviceInfo?.localUID}) {
            return main
        }
        return self.speakers.first
    }
    
    private var groupVolume: Int {
        guard speakers.count > 0 else {return 1}
        
        var volume = 0
        for sonos in speakers {
            volume += sonos.currentVolume
        }
        volume = volume / speakers.count
        
        return volume > 0 ? volume : 1
    }
    
    func getGroupVolume(_ completion:@escaping (_ vol: Int)->Void ) {
        var count = speakers.count
        for sonos in speakers {
            sonos.getVolume({ (_) in
                count -= 1
                if count == 0 {
                    completion(self.groupVolume)
                }
            })
        }
    }
    
    func addSpeaker(_ sonos: SonosDevice) {
        guard sonos.groupState?.groupID == self.groupID else {return}
        
        self.speakers.insert(sonos)
        if let groupName = sonos.groupState?.name, !groupName.isEmpty {
            self.name = groupName
        }
    }
    
    func removeIfGroupChanged(_ sonos: SonosDevice) {
        guard sonos.groupState?.groupID != self.groupID else {return}
        
        self.speakers.remove(sonos)
    }
    
    func remove(sonos: SonosDevice) {
        self.speakers.remove(sonos)
    }
    
    @objc func activateDeactivate(button: NSButton) {
        if button.state == .on {
            self.isActive = true
        }else if button.state == .off {
            self.isActive = false
        }
        
        self.delegate?.didChangeActiveState(group: self)
    }
    
    func setVolume(volume: Int){
        let groupVolume = self.groupVolume
        let increaseVol = volume - groupVolume
        for sonos in speakers {
            let currentVolume = sonos.currentVolume > 0 ? sonos.currentVolume : 1
            let updatedVolume = currentVolume + increaseVol
            sonos.setVolume(volume: updatedVolume)
        }
    }

    func setMute(muted: Bool) {
        for sonos in speakers {
            sonos.setMute(muted: muted)
        }
    }
    
    func play() {
        if let main = self.mainSpeaker {
            main.play()
        }else {
            self.speakers.forEach({$0.play()})
        }
    }
    
    func pause() {
        if let main = self.mainSpeaker {
            main.pause()
        }else {
            self.speakers.forEach({$0.pause()})
        }
    }
    
    func next() {
        if let main = self.mainSpeaker {
            main.next()
        }else {
            self.speakers.forEach({$0.next()})
        }
    }
    
    func previous() {
        if let main = self.mainSpeaker {
            main.previous()
        }else {
            self.speakers.forEach({$0.previous()})
        }
    }
    
    /**
     Get groups the play state
     */
    func getPlayState(_ completion: ((_ state: PlayState)->Void)? = nil) {
        mainSpeaker?.getPlayState(completion)
    }
    
    /**
     Update the current track and return it in the completion handler
     
     - Parameters:
     - completion: Callback contains TrackInfo
     */
    func updateCurrentTrack(_ completion: ((_ trackInfo: SonosTrackInfo)->Void)?=nil) {
        self.mainSpeaker?.updateCurrentTrack(completion)
    }
    
    
    var hashValue: Int {
        return self.groupID.hashValue
    }
    
    static func ==(l:SonosSpeakerGroup, r:SonosSpeakerGroup) -> Bool {
        return l.groupID == r.groupID
    }
    
}
