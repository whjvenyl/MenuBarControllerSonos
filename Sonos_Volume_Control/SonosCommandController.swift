//
//  SonosCommandController.swift
//  Sonos_Volume_Control
//
//  Created by Alexander Heinrich on 08.03.18.
//  Copyright © 2018 Sn0wfreeze Development UG. All rights reserved.
//

import Cocoa
import SWXMLHash


class SonosCommandController: NSObject {
    
}

class SonosCommand {
    var port: Int = 1400 //Default value
    var endpoint: SonosEndpoint
    var action: SonosActions
    var service: SononsService
    var bodyEntries = [String: String]()
    
    init(endpoint: SonosEndpoint, action: SonosActions, service: SononsService) {
        self.endpoint = endpoint
        self.action = action
        self.service = service
    }
    
    func execute(sonos: SonosController,_ completion: ((_ data: Data?)->Void)?=nil ) {
        
        let uri = "http://" + sonos.ip + ":" + String(sonos.port) + self.endpoint.rawValue;
        let content = "<s:Envelope\n xmlns:s=\"http://schemas.xmlsoap.org/soap/envelope/\""
            + "\n s:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\">\n<s:Body>"
            + "<u:\(self.action.rawValue)\n xmlns:u=\"\(self.service.rawValue)\">\n"
            + self.getBody()
            + "</u:\(self.action.rawValue)>\n"
            + "</s:Body>\n</s:Envelope>"
        
        let body =  content.data(using: .utf8)
        
        var request = URLRequest(url: URL(string: uri)!)
        request.httpMethod = "POST"
        request.addValue("text/xml", forHTTPHeaderField: "Content-Type")
        request.addValue("\(self.service.rawValue)#\(self.action.rawValue)", forHTTPHeaderField: "SOAPACTION")
        request.httpBody = body
        
        print("Request", request)
        print("Body", content)
        
        URLSession.init(configuration: .default).dataTask(with: request) { (data, response, error) in
            if let error = error {
                print("An error occurred ", error)
            }
            completion?(data)
            if let data = data {
                print(String.init(data:data, encoding: .utf8) ?? "No response")
            }
            
        }.resume()
    }
    
    func put(key: String, value: String) {
        let escapedValue = value.xmlSimpleEscape()
        bodyEntries[key] = escapedValue
    }
    
    func getBody() -> String {
        var bodyString = ""
        for (key, value) in self.bodyEntries{
            bodyString += "<\(key)>\(value)</\(key)>\n"
        }
        return bodyString
    }
}

enum SonosEndpoint:String {
    case rendering_endpoint = "/MediaRenderer/RenderingControl/Control"
}

enum SononsService:String {
    case rendering_service = "urn:schemas-upnp-org:service:RenderingControl:1"
}

enum SonosActions: String {
    case setVolume = "SetVolume"
    case getVolume = "GetVolume"
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
    
    func updateCurrentVolume() {
        getVolume { (volume) in }
    }
    
    @objc func activateDeactivate(button: NSButton) {
        if button.state == .on {
            self.active = true
        }else if button.state == .off {
            self.active = false
        }
    }
    
    static func ==(l:SonosController, r:SonosController) -> Bool {
        return l.udn == r.udn
    }
}


extension String
{
    typealias SimpleToFromRepalceList = [(fromSubString:String,toSubString:String)]
    
    // See http://stackoverflow.com/questions/24200888/any-way-to-replace-characters-on-swift-string
    //
    func simpleReplace( mapList:SimpleToFromRepalceList ) -> String
    {
        var string = self
        
        for (fromStr, toStr) in mapList {
            let separatedList = string.components(separatedBy:fromStr)
            if separatedList.count > 1 {
                string = separatedList.joined(separator: toStr)
            }
        }
        
        return string
    }
    
    func xmlSimpleUnescape() -> String
    {
        let mapList : SimpleToFromRepalceList = [
            ("&amp;",  "&"),
            ("&quot;", "\""),
            ("&#x27;", "'"),
            ("&#39;",  "'"),
            ("&#x92;", "'"),
            ("&#x96;", "-"),
            ("&gt;",   ">"),
            ("&lt;",   "<")]
        
        return self.simpleReplace(mapList: mapList)
    }
    
    func xmlSimpleEscape() -> String
    {
        let mapList : SimpleToFromRepalceList = [
            ("&",  "&amp;"),
            ("\"", "&quot;"),
            ("'",  "&#x27;"),
            (">",  "&gt;"),
            ("<",  "&lt;")]
        
        return self.simpleReplace(mapList: mapList)
    }
}


//String uri = "http://" + ip + ":" + SOAP_PORT + this.endpoint;
//String content = "<s:Envelope xmlns:s=\"http://schemas.xmlsoap.org/soap/envelope/\""
//    + " s:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\"><s:Body>"
//    + "<u:" + this.action + " xmlns:u=\"" + this.service + "\">"
//    + this.getBody()
//    + "</u:" + this.action + ">"
//    + "</s:Body></s:Envelope>";
//RequestBody body = RequestBody.create(MediaType.parse("application/text"), content.getBytes("UTF-8"));
//Request request = new Request.Builder().url(uri).addHeader("Content-Type", "text/xml")
//    .addHeader("SOAPACTION", this.service + "#" + this.action).post(body).build();
//String response = getHttpClient().newCall(request).execute().body().string();
//response = unescape(response);
//handleError(ip, response);
//return response;

