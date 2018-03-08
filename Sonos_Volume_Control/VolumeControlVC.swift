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

    @IBOutlet weak var sonosStack: NSStackView!
    @IBOutlet weak var sonosSlider: NSSlider!
    @IBOutlet weak var errorMessageLabel: NSTextField!
    
    private let discovery: SSDPDiscovery = SSDPDiscovery.defaultDiscovery
    fileprivate var session: SSDPDiscoverySession?
    
    var sonosSystems = [SonosController]()
    var devicesFoundCurrentSearch = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        if sonosSystems.count == 0 {
            errorMessageLabel.isHidden = false
        }
    }
    
    override func viewWillAppear() {
        searchForDevices()
        updateSliderVolume()
    }
    
    func searchForDevices() {
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
        print("Found device \(response)")
        retrieveDeviceInfo(response: response)
    }
    
    func retrieveDeviceInfo(response: SSDPMSearchResponse) {
        URLSession.init(configuration: URLSessionConfiguration.default).dataTask(with: response.location) { (data, resp, err) in
            if let data = data {
                let xml =  SWXMLHash.parse(data)
                let sonosDevice = SonosController(xml: xml, url: response.location)
                DispatchQueue.main.async {
                    self.addDeviceToList(sonos: sonosDevice)
                }
            }
        }.resume()
    }
    
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
        self.sonosSystems.append(sonos)
        let button = NSButton(checkboxWithTitle: sonos.readableName, target: sonos, action: #selector(SonosController.activateDeactivate(button:)))
        button.state = .on
        self.sonosStack.addArrangedSubview(button)
        devicesFoundCurrentSearch += 1
        self.errorMessageLabel.isHidden = true
        
        
        sonos.getVolume { (volume) in
            if self.sonosSlider.integerValue < volume {
                self.sonosSlider.integerValue = volume
            }
        }
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
    
    @IBAction func setVolume(_ sender: NSSlider) {
        for sonos in sonosSystems {
            guard sonos.active else {continue}
            sonos.setVolume(volume: sender.integerValue)
        }
    }
    
    func updateSliderVolume() {
        sonosSystems.first(where: {$0.active})?.getVolume({ (volume) in
            self.sonosSlider.integerValue = volume
        })
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


