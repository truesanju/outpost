//
//  ViewController.swift
//  Outpost
//
//  Created by Sanjay Pushparajan on 1/14/18.
//  Copyright © 2018 Sanjay Pushparajan. All rights reserved.
//

import UIKit
import Metal
import MetalKit
import ARKit
import WebKit
import SpriteKit
import Foundation

extension MTKView : RenderDestinationProvider {
}

class ViewController: UIViewController, MTKViewDelegate, ARSessionDelegate {
    
    let DEBUG = true
    let DEFAULT_URL = "https://outpost-web.herokuapp.com/"
    let DEV_URL = "https://8d75ae0e.ngrok.io/"
    
    var webView:WKWebView!
    
    var session: ARSession!
    var renderer: Renderer!
    
    let anchors = [NSDictionary]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        session = ARSession()
        session.delegate = self
        
       
        
        // Set the view to use the default device
        if let view = self.view as? MTKView {
            
            view.device = MTLCreateSystemDefaultDevice()
            view.backgroundColor = UIColor.clear
            view.delegate = self
            
            guard view.device != nil else {
                print("Metal is not supported on this device")
                return
            }
            
            //Create web view
            let userContentController = WKUserContentController()
            let webConfiguration = WKWebViewConfiguration()
            webConfiguration.userContentController = userContentController
            
            webView = WKWebView(frame: view.bounds, configuration: webConfiguration)
            webView.isOpaque = false
            webView.backgroundColor = UIColor.clear
            webView.scrollView.backgroundColor = UIColor.clear
            webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            
            //Add as subview to MTKView
            view.addSubview(webView)
            self.loadURL(URLAsString: DEV_URL)
            
            // Configure the renderer to draw to the view
            renderer = Renderer(session: session, metalDevice: view.device!, renderDestination: view)
            
            renderer.drawRectResized(size: view.bounds.size)
            
            
        }
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(ViewController.handleTap(gestureRecognize:)))
        view.addGestureRecognizer(tapGesture)
        
//        //Clear website cache
//        let allWebsiteDataTypes = WKWebsiteDataStore.allWebsiteDataTypes()
//        WKWebsiteDataStore.default().fetchDataRecords(ofTypes: allWebsiteDataTypes) { (data) in
//            WKWebsiteDataStore.default().removeData(ofTypes: allWebsiteDataTypes, for: data, completionHandler: {
//                print("Website cache cleared successfully.")
//            })
//        }
        
        //TODO: Load WebXR polyfill
        
      
        
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        
        // Run the view's session
        session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        session.pause()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }
    
    @objc
    func handleTap(gestureRecognize: UITapGestureRecognizer) {
        // Create anchor using the camera's current position
        if let currentFrame = session.currentFrame {
            
            // Create a transform with a translation of 0.2 meters in front of the camera
            var translation = matrix_identity_float4x4
            translation.columns.3.z = -0.2
            let transform = simd_mul(currentFrame.camera.transform, translation)
            
            // Add a new anchor to the session
            let anchor = ARAnchor(transform: transform)
            session.add(anchor: anchor)
        }
    }
    
    // MARK: - MTKViewDelegate
    func loadURL (URLAsString: String){
        let URLToLoad = URL(string: URLAsString)
        let URLLoadRequest = URLRequest(url: URLToLoad!)
        webView.load(URLLoadRequest)
    }
    
    // Called whenever view changes orientation or layout is changed
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        renderer.drawRectResized(size: size)
    }
    
    // Called whenever the view needs to render
    func draw(in view: MTKView) {
        renderer.update()
    }
    
    // MARK: - ARSessionDelegate
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
    
    //Called whenever frame updates
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        DispatchQueue.main.async {
            
            let orientation = UIApplication.shared.statusBarOrientation
            let viewMatrix = frame.camera.viewMatrix(for: orientation)
            let projectionMatrix = frame.camera.projectionMatrix(for: orientation, viewportSize: self.webView.frame.size, zNear: 0.02, zFar: 20)
            
            let viewMatrixAsArray = self.Float4x4ToArray(matrix: simd_inverse(viewMatrix))
            let projectionMatrixAsArray = self.Float4x4ToArray(matrix: projectionMatrix)
            
            let serializedViewMatrix = self.serializeMatrix(matrixToSerialize:(viewMatrix))
            let serializedProjectionMatrix = self.serializeMatrix(matrixToSerialize: projectionMatrix)
            
            let lightEstimate = frame.lightEstimate
            
            if(lightEstimate != nil){
                let ambient:Float = Float(lightEstimate!.ambientIntensity/1000.0)
                //let temperature = lightEstimate!.ambientColorTemperature
                
                self.webView.evaluateJavaScript("ambientLightUpdate('\(ambient)');", completionHandler: { (result, error) in
                    print("Light estimate updated")
                });
            }
            
           
            
            self.webView.evaluateJavaScript("cameraMatrixUpdate('\(viewMatrixAsArray)','\(projectionMatrixAsArray)');", completionHandler: { (result, error) in
                
                print(result)
                
                if(error != nil){
                    print(error)
                }
            })

        }
    }
    
    func Float3ToArray(matrix: simd_float3) -> [Float] {
        return [matrix.x,matrix.y,matrix.z]
    }
    
    func Float4x4ToArray(matrix: simd_float4x4) -> [Float] {
        return [matrix.columns.0.x, matrix.columns.0.y, matrix.columns.0.z, matrix.columns.0.w,
                matrix.columns.1.x, matrix.columns.1.y, matrix.columns.1.z, matrix.columns.1.w,
                matrix.columns.2.x, matrix.columns.2.y, matrix.columns.2.z, matrix.columns.2.w,
                matrix.columns.3.x, matrix.columns.3.y, matrix.columns.3.z, matrix.columns.3.w]
    }
    
    func serializeMatrix (matrixToSerialize:matrix_float4x4) -> String? {
        let encoder = JSONEncoder()
        do{
            let matrixJSONData = try encoder.encode(Float4x4ToArray(matrix: matrixToSerialize))
            return String(data: matrixJSONData, encoding: String.Encoding.utf8)!
        } catch {
            print("Unable to serialize matrix")
            return nil
        }
    }
    
}
