//
//  VolumeControlVC.swift
//  Sonos_Volume_Control
//
//  Created by Alexander Heinrich on 06.03.18.
//  Copyright © 2018 Sn0wfreeze Development UG. All rights reserved.
//

import Cocoa
import SWXMLHash

class VolumeControlVC: NSViewController {

    //MARK: Properties
    @IBOutlet weak var sonosStack: NSStackView!
    @IBOutlet weak var volumeSlider: NSSlider!
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
    var speakerButtons: [SonosController: NSButton] = [:]
    var lastDiscoveryDeviceList = [SonosController]()
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
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
//        self.addTest()
        self.setupScrollView()
    }
    
    func addTest() {
        for i in 0..<2 {
            let testSonos = SonosController(roomName: "Room\(i)", deviceName: "PLAY:3", url: URL(string:"http://192.168.178.9\(i)")!, ip: "192.168.178.9\(i)", udn: "some-udn-\(i)")
            testSonos.playState = .playing
            self.addDeviceToList(sonos: testSonos)
            self.controlsView.isHidden = false
        }
    }
    
    //MARK: - Updating Sonos Players
    /**
     Add a device to the list of devices
     
     - Parameters:
     - sonos: The Sonos Device which was found and should be added
     */
    func addDeviceToList(sonos: SonosController) {
        guard sonosSystems.contains(sonos) == false else {return}
        
        //New sonos system. Add it to the list
        sonos.delegate = self
        self.sonosSystems.append(sonos)
        
        self.updateSonosDeviceList()
        
        if self.sonosSystems.count == 1 {
            self.updateState()
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
        
        self.sortSpeakers()
        
        //Add all sonos buttons
        for sonos in sonosSystems {
            let button = NSButton(checkboxWithTitle: sonos.readableName, target: sonos, action: #selector(SonosController.activateDeactivate(button:)))
            button.state = sonos.active ? .on : .off
            self.sonosStack.addArrangedSubview(button)
            self.speakerButtons[sonos] = button
        }
        
        self.setupScrollView()
    }
    
    /**
     Remove old devices which have not been discovered for 10 minutes
    */
    func removeOldDevices() {
        //Remove undiscovered devices
        //All devices which haven't been found on last discovery
        let undiscoveredDevices = self.sonosSystems.filter({self.lastDiscoveryDeviceList.contains($0) == false})
        for sonos in undiscoveredDevices {
            guard let button = self.speakerButtons[sonos],
                button.superview == self.sonosStack else {continue}
            // Remove all buttons of speakers which have not been discovered
            self.sonosStack.removeView(button)
            self.speakerButtons[sonos] = nil
        }
        
        self.sonosSystems = self.sonosSystems.filter({undiscoveredDevices.contains($0) == false})
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
            self.sonosGroups[gId] = group
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
    
    func setupScrollView() {
       self.sonosScrollContainer.scrollToTop()
       self.sonosScrollContainer.isScrollingEnabled = self.sonosSystems.count > 4
    }
    
    func updateState() {
        let firstSonos = sonosSystems.first(where: {$0.active})
        firstSonos?.getVolume({ (volume) in
            if firstSonos?.muted == true {
                self.volumeSlider.integerValue = 0
            }else {
                self.volumeSlider.integerValue = volume
            }
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
        case .paused, .stopped:
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
            if sonos.playState != .playing {
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
    
}

//MARK: - Sonos Discovery

extension VolumeControlVC: SSDPDiscoveryDelegate {
    
    func searchForDevices() {
        self.stopDiscovery()
        self.lastDiscoveryDeviceList.removeAll()
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
                self.devicesFoundCurrentSearch += 1
                let xml =  SWXMLHash.parse(data)
                let udn = xml["root"]["device"]["UDN"].element?.text
                //Check if device is already available
                if let sonos = self.sonosSystems.first(where: {$0.udn == udn}) {
                    //Update the device
                    sonos.update(withXML: xml, url: response.location)
                    self.lastDiscoveryDeviceList.append(sonos)
                }else {
                    let sonosDevice = SonosController(xml: xml, url: response.location, { (sonos) in
                        self.updateGroups(sonos: sonos)
                    })
                    self.lastDiscoveryDeviceList.append(sonosDevice)
                    
                    DispatchQueue.main.async {
                        self.addDeviceToList(sonos: sonosDevice)
                    }
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
    
    func discoveredService(response: SSDPMSearchResponse, session: SSDPDiscoverySession) {
        print("Found service \(response)")
    }
    
    func closedSession(_ session: SSDPDiscoverySession) {
        print("Session closed")
        self.updateState()
        
        self.removeOldDevices()
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

//MARK: Sonos Delegate
extension VolumeControlVC: SonosControllerDelegate {
    func didUpdateActiveState(forSonos sonos: SonosController, isActive: Bool) {
        self.updateState()
    }
}


