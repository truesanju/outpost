//
//  OutpostConnector.swift
//  Outpost
//
//  Created by Sanjay Pushparajan on 1/23/18.
//  Copyright © 2018 Sanjay Pushparajan. All rights reserved.
//

import Foundation
import ARKit
import WebKit

class OutpostConnector: NSObject, ARSessionDelegate, WKUIDelegate {
    
    var webView: WKWebView!
    var session: ARSession!
    
    let DEFAULT_URL = "www.google.com"
    
    func drawWebView (onParentView:UIView, usingARSession: ARSession) {
        self.session = usingARSession
        
        //Set up webview size
        let viewsizeRect = onParentView.bounds
        let webConfiguration = WKWebViewConfiguration()
        self.webView = WKWebView(frame: viewsizeRect, configuration: webConfiguration)
        loadURL(URLAsString: DEFAULT_URL)
        onParentView.addSubview(webView)
    }
    
    func loadURL (URLAsString: String){
        let URLToLoad = URL(fileURLWithPath: URLAsString)
        let URLLoadRequest = URLRequest(url: URLToLoad)
        self.webView.load(URLLoadRequest)
    }
    
    //Store URL in user defaults
    func storeURLInDefaults (urlToStore:String){
        let defaults = UserDefaults.standard
        defaults.set(urlToStore, forKey: "url")
    }
    
    
    //Fetch current default URL
    func getURLFromDefaults () -> String? {
        let defaults = UserDefaults.standard
        if let url = defaults.string(forKey: "url") {
            return url
        } else {
            print("No default URL found.")
            return nil
        }
    }
    
}
