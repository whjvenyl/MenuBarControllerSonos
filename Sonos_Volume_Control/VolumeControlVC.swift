//
//  VolumeControlVC.swift
//  Sonos_Volume_Control
//
//  Created by Alexander Heinrich on 06.03.18.
//  Copyright © 2018 Sn0wfreeze Development UG. All rights reserved.
//

import Cocoa
import SWXMLHash

class VolumeControlVC: NSViewController, SSDPDiscoveryDelegate {

    //MARK: Properties
    @IBOutlet weak var sonosStack: NSStackView!
    @IBOutlet weak var sonosSlider: NSSlider!
    @IBOutlet weak var errorMessageLabel: NSTextField!
    @IBOutlet weak var controlsView: NSView!
    @IBOutlet weak var pauseButton: NSButton!
    @IBOutlet weak var sonosScrollContainer: CustomScrolllView!
    let defaultHeight: CGFloat = 143.0
    let defaultWidth:CGFloat = 228.0
    let maxHeight: CGFloat = 215.0
    
    private let discovery: SSDPDiscovery = SSDPDiscovery.defaultDiscovery
    fileprivate var session: SSDPDiscoverySession?
    
    var sonosSystems = [SonosController]()
    var sonosGroups: [String : SonosSpeakerGroup] = [:]
    var devicesFoundCurrentSearch = 0
    
    //MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        if sonosSystems.count == 0 {
            errorMessageLabel.isHidden = false
        }
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        searchForDevices()
        updateState()
//        self.addTest()
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        self.scrollToTop()
    }
    
    func addTest() {
        for i in 0..<7 {
            let testSonos = SonosController(roomName: "Room\(i)", deviceName: "PLAY:3", url: URL(string:"http://192.168.178.9\(i)")!, ip: "192.168.178.9\(i)", udn: "some-udn-\(i)")
            testSonos.playState = .playing
            self.addDeviceToList(sonos: testSonos)
            self.controlsView.isHidden = false
        }
    }
    
    //MARK: - Sonos Discovery
    func searchForDevices() {
        self.devicesFoundCurrentSearch = 0
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
    
    func discoveredDevice(response: SSDPMSearchResponse, session: SSDPDiscoverySession) {
//        print("Found device \(response)")
        retrieveDeviceInfo(response: response)
    }
    
    func retrieveDeviceInfo(response: SSDPMSearchResponse) {
        URLSession.init(configuration: URLSessionConfiguration.default).dataTask(with: response.location) { (data, resp, err) in
            if let data = data {
                let xml =  SWXMLHash.parse(data)
                let sonosDevice = SonosController(xml: xml, url: response.location, { (sonos) in
                    self.updateGroups(sonos: sonos)
                })
                DispatchQueue.main.async {
                    self.addDeviceToList(sonos: sonosDevice)
                }
            }
        }.resume()
    }
    
    func sortSpeakers() {
        //Sort the sonos systems
        self.sonosSystems.sort { (lhs, rhs) -> Bool in
            if lhs.active && !rhs.active {
                return true
            }
            if rhs.active && !lhs.active {
                return false
            }
            
            return lhs.active == rhs.active && lhs.readableName < rhs.readableName
        }
    }
    
    //MARK: - Updating Sonos Players
    /**
     Add a device to the list of devices
     
     - Parameters:
     - sonos: The Sonos Device which was found and should be added
     */
    func addDeviceToList(sonos: SonosController) {
        if sonosSystems.contains(sonos),
            let idx = sonosSystems.index(of: sonos) {
            replaceSonos(atIndex: idx, withSonos: sonos)
            return
        }
        
        //New sonos system. Add it to the list
        sonos.delegate = self
        self.sonosSystems.append(sonos)
        devicesFoundCurrentSearch += 1
        
        self.updateSonosDeviceList()
        
        if self.sonosSystems.count == 1 {
            self.updateState()
        }
        
        if self.sonosSystems.count > 4 {
            self.scrollToTop()
        }
    }
    
    func updateSonosDeviceList() {
        //Remove error label
        if self.sonosSystems.count > 0 {
            self.errorMessageLabel.isHidden = true
        }
        
        //Remove all buttons
        for view in self.sonosStack.subviews {
            self.sonosStack.removeView(view)
        }
        
        //Add all sonos buttons
        for sonos in sonosSystems {
            let button = NSButton(checkboxWithTitle: sonos.readableName, target: sonos, action: #selector(SonosController.activateDeactivate(button:)))
            button.state = sonos.active ? .on : .off
            self.sonosStack.addArrangedSubview(button)
        }
    }
    
    /**
     Update the groups controllers
     
     - Parameters:
     - sonos: The Sonos speaker which should be added to the group
     */
    func updateGroups(sonos: SonosController) {
        guard let gId = sonos.groupState?.groupID else {return}
        
        if var group = self.sonosGroups[gId] {
            group.speakers.insert(sonos)
        }else {
            var group = SonosSpeakerGroup(groupID: gId)
            group.speakers.insert(sonos)
        }
        
        //TODO:  Update the groups view
    }
    
    /**
     Found a duplicate sonos. Check if the IP address has changed
     
     - Parameters:
        - idx: Index at which the equal sonos is placed in sonosSystems
        - sonos: The newly discovered sonos
     */
    func replaceSonos(atIndex idx: Int, withSonos sonos: SonosController) {
        let eqSonos = sonosSystems[idx]
        if eqSonos.ip != sonos.ip {
            //Ip address changes
            sonosSystems.remove(at: idx)
            sonosSystems.insert(sonos, at: idx)
            sonos.active = eqSonos.active
        }
    }
    
    func scrollToTop() {
        self.sonosScrollContainer.verticalScroller?.floatValue = 0.0
        self.sonosScrollContainer.contentView.scroll(to: NSPoint(x: 0.0, y: self.sonosScrollContainer.documentView!.frame.maxY - self.sonosScrollContainer.contentView.bounds.height))
        
        self.sonosScrollContainer.isScrollingEnabled = self.sonosSystems.count > 4
    }
    
    func updateState() {
        let firstSonos = sonosSystems.first(where: {$0.active})
        firstSonos?.getVolume({ (volume) in
            self.sonosSlider.integerValue = volume
        })
        
        firstSonos?.getPlayState({ (state) in
            self.updatePlayButton(forState: state)
        })
    }
    
    func updatePlayButton(forState state: PlayState) {
        switch (state) {
        case .playing:
            self.pauseButton.image = #imageLiteral(resourceName: "ic_pause")
            self.controlsView.isHidden = false
        case .paused:
            self.pauseButton.image = #imageLiteral(resourceName: "ic_play_arrow")
            self.controlsView.isHidden = false
        default:
            self.controlsView.isHidden = true
        }
    }
    
    //MARK: - Interactions
    @IBAction func setVolume(_ sender: NSSlider) {
        for sonos in sonosSystems {
            guard sonos.active else {continue}
            sonos.setVolume(volume: sender.integerValue)
        }
    }
    
    @IBAction func playPause(_ sender: Any) {
        for sonos in sonosSystems {
            guard sonos.active else {continue}
            if sonos.playState == .paused {
                sonos.play()
                self.updatePlayButton(forState: sonos.playState)
            }else if sonos.playState == .playing {
                sonos.pause()
                self.updatePlayButton(forState: sonos.playState)
            }
            
            
        }
    }
    @IBAction func nextTrack(_ sender: Any) {
        for sonos in sonosSystems {
            guard sonos.active else {continue}
            sonos.next()
        }
    }
    
    @IBAction func prevTrack(_ sender: Any) {
        for sonos in sonosSystems {
            guard sonos.active else {continue}
            sonos.previous()
        }
    }
    
    @IBAction func showMenu(_ sender: NSView) {
        let appMenu = NSMenu()
        appMenu.addItem(withTitle: "Show Imprint", action: #selector(openImprint), keyEquivalent: "")
        appMenu.addItem(withTitle: "Software licenses", action: #selector(openLicenses), keyEquivalent: "")
        appMenu.addItem(withTitle: "Quit", action: #selector(quitApp), keyEquivalent: "")
        
        
        let p = NSPoint(x: sender.frame.origin.x, y: sender.frame.origin.y - (sender.frame.height / 2))
        appMenu.popUp(positioning: nil, at: p, in: sender.superview)
    }
    
    @objc func quitApp() {
        NSApp.terminate(self)
    }
    
    @objc func openImprint() {
        NSWorkspace.shared.open(URL(string:"http://sn0wfreeze.de/?p=522")!)
    }
    
    @objc func openLicenses() {
        NSWorkspace.shared.open(URL(string:"http://sn0wfreeze.de/?p=525")!)
    }
    
    func discoveredService(response: SSDPMSearchResponse, session: SSDPDiscoverySession) {
        print("Found service \(response)")
    }
    
    func closedSession(_ session: SSDPDiscoverySession) {
        print("Session closed")
        if devicesFoundCurrentSearch != sonosSystems.count {
            //Unequal value. One system must have disappeared
            //Restart search and delete devices
            self.sonosSystems.removeAll()
            self.devicesFoundCurrentSearch = 0
            for view in self.sonosStack.subviews {
                self.sonosStack.removeView(view)
            }
            self.searchForDevices()
        }else {
            updateState()
        }
    }
    
}

extension VolumeControlVC {
    // MARK: Storyboard instantiation
    static func freshController() -> VolumeControlVC {
        //1.
        let storyboard = NSStoryboard(name: NSStoryboard.Name(rawValue: "Main"), bundle: nil)
        //2.
        let identifier = NSStoryboard.SceneIdentifier(rawValue: "VolumeControlVC")
        //3.
        guard let viewcontroller = storyboard.instantiateController(withIdentifier: identifier) as? VolumeControlVC else {
            fatalError("Why cant i find QuotesViewController? - Check Main.storyboard")
        }
        return viewcontroller
    }
}

extension VolumeControlVC: SonosControllerDelegate {
    func didUpdateActiveState(forSonos sonos: SonosController, isActive: Bool) {
        self.updateState()
    }
}


