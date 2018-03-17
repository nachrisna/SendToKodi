//
//  ShareViewController.swift
//  SendToKodiAction
//
//  Created by Tobias Tangemann on 15.01.16.
//  Copyright © 2016 Tobias Tangemann. All rights reserved.
//  Updated by Max Grass to support SendToKodi of firsttris on 17.03.18.

import Cocoa

class ShareViewController: NSViewController {
    @IBOutlet weak var progress: NSProgressIndicator!
    
    override func loadView() {
        super.loadView()
        
        progress.startAnimation(nil)
        
        let item = self.extensionContext!.inputItems[0] as! NSExtensionItem
        
        if let attachments = item.attachments {
            (attachments.first as! NSItemProvider).loadItem(forTypeIdentifier: kUTTypeURL as String, options: nil, completionHandler: { (item, error) -> Void in
                self.sendRequestToKodi(item as! URL)
            })
        }
        else {
            let cancelError = NSError(domain: NSCocoaErrorDomain, code: NSUserCancelledError, userInfo: nil)
            self.extensionContext!.cancelRequest(withError: cancelError)
        }
    }
    
    @IBAction func cancel(_ sender: NSButton) {
        progress.stopAnimation(nil)
        
        self.extensionContext!.cancelRequest(withError: NSError(domain: NSCocoaErrorDomain, code: NSUserCancelledError, userInfo: nil))
    }
    
    func generateRequestDataFromUrl(_ url: URL) -> Data! {
            return ("{\"jsonrpc\": \"2.0\", \"method\": \"Player.Open\", \"params\": " +
                "{\"item\": {\"file\" : \"plugin://plugin.video.sendtokodi/?\(url)\" }}, \"id\" : \"0\"}")
                .data(using: String.Encoding.utf8)
    }
    
    func sendRequestToKodi(_ url: URL) {
        let session = URLSession.shared
        let hostname = UserDefaults(suiteName: USER_DEFAULTS_SUITE)!.string(forKey: "kodi_hostname")!
        
        let requestData = self.generateRequestDataFromUrl(url)
        
        let request = NSMutableURLRequest(url: URL(string: "http://\(hostname):8080/jsonrpc")!)
        request.httpMethod = "POST"
        request.setValue("application/json",         forHTTPHeaderField: "Accept")
        request.setValue("application/json",         forHTTPHeaderField: "Content-Type")
        request.setValue(String(describing: requestData?.count), forHTTPHeaderField: "Content-Length")
        request.httpBody = requestData
        
        let task = session.dataTask(with: request as URLRequest, completionHandler: {
            data, response, error in
            
            if error == nil {
                self.extensionContext!.completeRequest(returningItems: nil, completionHandler: nil)
            }
            else {
                self.extensionContext!.cancelRequest(withError: NSError(domain: NSCocoaErrorDomain, code: NSUserCancelledError, userInfo: nil))
            }
        }) 
        task.resume()
    }
}
