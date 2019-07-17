//
//  ViewController.swift
//  ARKitHorizontalPlaneDemo
//
//  Created by Jayven Nhan on 11/14/17.
//  Copyright © 2017 Jayven Nhan. All rights reserved.
//

import UIKit
import ARKit
import AWSS3
import AWSCore


class ForWatchUI:UIViewController {
    // 20180628 add
    //[start-20190701-GT0006-add]//
    var choose = ""
    // choose 作為最後選擇的模型
    
    var final_url:URL? = URL(string: "https://s3-ap-northeast-1.amazonaws.com/howtest.bk/GTtest_arkit_model/cup.snc")!
    // final_url 作為最後選擇的模型Url
    
    var test_node:SCNNode? = nil
    
    var putData = [String : String]()
    //var putData = ["1":"a","2":"b"]
    //putData 用來存放我所輸入的文字 做成字典形式，與自己輸入的值做連動
    
    var load_model_data = [String:Array<Float>]()
    // 還原模型後的data_model
    
    
    @IBOutlet weak var sceneView: ARSCNView!
    
    // 20190702 GT add start//
    //Label 設置//
    @IBOutlet weak var label: UILabel!
    
    
    func setLabel(text: String) {
        print("start setlabel")
        label.text = text
    }
    // 20190702 GT add end//
    override func viewDidLoad() {
        super.viewDidLoad()
        //[end---20190628-GT0005-add]//
        
        print("start")
        sceneView.delegate = self as! ARSCNViewDelegate
        configureLighting()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        //        setUpSceneView()
        resetTrackingConfiguration()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
    }
    
    
    //[start-20190628-GT0001-add]//
    // 設計跳出視窗 請使用者輸入想要download的檔案名


    
    // Start 20190702 GT add//
    // 儲存worldMap
    var worldMapURL: URL = {
        do {
            return try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                .appendingPathComponent("worldMapURL")
        } catch {
            fatalError("Error getting world map URL from document directory.")
        }
    }()
    
    
    func archive(worldMap: ARWorldMap) throws {
        let data = try NSKeyedArchiver.archivedData(withRootObject: worldMap, requiringSecureCoding: true)
        try data.write(to: self.worldMapURL, options: [.atomic])
    }

    func retrieveWorldMapData(url: URL) -> Data? {
        do {
            return try Data(contentsOf: url)
        } catch {
            self.setLabel(text: "Error retrieving world map data.")
            return nil
        }
    }
    func unarchive(worldMapData data: Data) -> ARWorldMap? {
        guard let unarchievedObject = try? NSKeyedUnarchiver.unarchivedObject(ofClass: ARWorldMap.self, from: data),
            let worldMap = unarchievedObject else { return nil }
        return worldMap
    }
    @IBAction func loadBarButtonItemDidTouch(_ sender: UIButton)
    {
        print("load map start")
        setLabel(text:"load map start")
        let url = self.final_url
        print(url)
        
        let worldmap_url = URL(string: "https://s3-ap-northeast-1.amazonaws.com/howtest.bk/GTtest_arkit_model/worldmap")!
        if let loadDict = NSDictionary(contentsOf: URL(string: "https://s3-ap-northeast-1.amazonaws.com/howtest.bk/GTtest_arkit_model/model_data")!) as? [String:Array<Float>]{
            load_model_data = loadDict
        }
        guard let worldMapData = retrieveWorldMapData(url: worldmap_url),
            let worldMap = unarchive(worldMapData: worldMapData) else { return }
        print(worldMap.anchors)
        resetTrackingConfiguration(with: worldMap)
    }
    
    func resetTrackingConfiguration(with worldMap: ARWorldMap? = nil) {
        if let worldMap = worldMap {
            let configuration = ARWorldTrackingConfiguration()
            configuration.planeDetection = [.horizontal]
            let options: ARSession.RunOptions = [.resetTracking, .removeExistingAnchors]
            //設定arscnview run option
            configuration.initialWorldMap = worldMap
            setLabel(text: "Found saved world map.")
            sceneView.debugOptions = [.showFeaturePoints]
            sceneView.session.run(configuration, options: options)
        }
        else {
            let configuration = ARWorldTrackingConfiguration()
            configuration.planeDetection = [.horizontal]
            //設定AR seesion 配置方式
            let options: ARSession.RunOptions = [.resetTracking, .removeExistingAnchors]
            //設定arscnview run option
            
            sceneView.scene.rootNode.enumerateChildNodes { (node, stop) in
                node.removeFromParentNode()
                
                setLabel(text: "Move camera around to map your surrounding space.")
            }
            
            sceneView.debugOptions = [.showFeaturePoints]
            sceneView.session.run(configuration, options: options)
        }
    }
    @IBAction func resetBarButtonItemDidTouch(_ sender: UIBarButtonItem) {
        resetTrackingConfiguration()
    }
    
    // End 20190702 GT add//

    func configureLighting() {
        sceneView.autoenablesDefaultLighting = true
        sceneView.automaticallyUpdatesLighting = true
    }
    
    

}


// 偵測平面 start
extension ForWatchUI: ARSCNViewDelegate {
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        // 20190710 GT mod//
        // 判斷ANchor name來放模型，若無，則放平面
        print("i an anchor",anchor)
            if anchor.name != nil
            {
                if (anchor.name!.contains("cup")){
                    print("i did cup one")
                    do{
                        var shipScene = try SCNScene(url: URL(string: "https://s3-ap-northeast-1.amazonaws.com/howtest.bk/GTtest_arkit_model/cup.scn")! , options: nil),
                        cupNode = shipScene.rootNode.childNode(withName: "cup", recursively: false)
                        cupNode?.position =  SCNVector3(anchor.transform.translation)
                        cupNode?.scale = SCNVector3(load_model_data[anchor.name!]![0],load_model_data[anchor.name!]![1],load_model_data[anchor.name!]![2])
                        cupNode?.rotation.y = 1
                        cupNode?.rotation.w = load_model_data[anchor.name!]![3]
                        //print(cupNode)
                        sceneView.scene.rootNode.addChildNode(cupNode!)
                        print("i did cup two")
                    }
                    catch{
                        print("fail cup QQ")
                    }
                }
                    
                else if (anchor.name!.contains("test")){
                    let videoItem = AVPlayerItem(url: URL(string: "https://s3-ap-northeast-1.amazonaws.com/howtest.bk/GTtest_arkit_model/test.mp4")! )
                    let player = AVPlayer(playerItem: videoItem)
                    //initialize video node with avplayer
                    let videoNode = SKVideoNode(avPlayer: player)
                    player.play()
                    // add observer when our player.currentItem finishes player, then start playing from the beginning
                    NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: player.currentItem, queue: nil) { (notification) in
                        player.seek(to: kCMTimeZero)
                        player.play()
                        print("Looping Video")
                    }
                    // set the size (just a rough one will do)
                    let videoScene = SKScene(size: CGSize(width: 480, height: 360)) // 底版大小
                    
                    // center our video to the size of our video scene
                    videoNode.position = CGPoint(x: 480/2, y: 360/2) //放置中心
                    // invert our video so it does not look upside down
                    videoNode.yScale = -1
                    videoNode.size = CGSize(width: 480, height: 360) // 調整影片大小
                    // add the video to our scene
                    videoScene.addChild(videoNode)
                    // finally add the plane node (which contains the video node) to the added node
                    let background = SCNPlane(width: CGFloat(1), height: CGFloat(1))
                    background.firstMaterial?.diffuse.contents = videoScene
                    background.firstMaterial?.isDoubleSided = true
                    let backgroundNode = SCNNode(geometry: background)
                    backgroundNode.position =  SCNVector3(anchor.transform.translation)
                    
                    backgroundNode.scale = SCNVector3(load_model_data[anchor.name!]![0],load_model_data[anchor.name!]![1],load_model_data[anchor.name!]![2])
                    backgroundNode.rotation.y = 1
                    backgroundNode.rotation.w = load_model_data[anchor.name!]![3]
                    
                    print("test1")
                    sceneView.scene.rootNode.addChildNode(backgroundNode)
                    print("test2")
                    print("i am backgroundNode",backgroundNode)
                }
            else{
                print("i am plane")
            }
    }
        else{
            // 1
            guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
            // 2
            let width = CGFloat(planeAnchor.extent.x)
            let height = CGFloat(planeAnchor.extent.z)
            let plane = SCNPlane(width: width, height: height)
            // 3
            plane.materials.first?.diffuse.contents = UIColor.transparentLightBlue
            // 4
            let planeNode = SCNNode(geometry: plane)
            // 5
            let x = CGFloat(planeAnchor.center.x)
            let y = CGFloat(planeAnchor.center.y)
            let z = CGFloat(planeAnchor.center.z)
            planeNode.position = SCNVector3(x,y,z)
            planeNode.eulerAngles.x = -.pi / 2
            // 6
            node.addChildNode(planeNode)
            print("I AM NODE",node)
        }
    // 20190710 GT//
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        // 1
        guard let planeAnchor = anchor as?  ARPlaneAnchor,
            let planeNode = node.childNodes.first,
            let plane = planeNode.geometry as? SCNPlane
            else { return }
        
        // 2
        let width = CGFloat(planeAnchor.extent.x)
        let height = CGFloat(planeAnchor.extent.z)
        plane.width = width
        plane.height = height
        
        // 3
        let x = CGFloat(planeAnchor.center.x)
        let y = CGFloat(planeAnchor.center.y)
        let z = CGFloat(planeAnchor.center.z)
        planeNode.position = SCNVector3(x, y, z)
    }
    
}
// 偵測平面 End
}
