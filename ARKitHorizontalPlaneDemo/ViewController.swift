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


class ViewController:UIViewController {
// 20180628 add
//[start-20190701-GT0006-add]//
    var choose = ""
// choose 作為最後選擇的模型
    
    var final_url:URL? = nil
// final_url 作為最後選擇的模型Url
    
    var isLoadingState = false
// 判斷是否為load狀態
    
    var Data_anchor = [ARAnchor]()
    var Data_Node = [SCNNode]()
// 存儲所有anchor and node位置

    var putData = [String : String]()
//putData 用來存放我所輸入的文字 做成字典形式，與自己輸入的值做連動
// 20190712 GT add start//
//手勢縮放的初始值//
    var beginObjScale: Float = 1
    var beginPinchScale: CGFloat = 1
// 紀錄 tap的模型
    var FocusAnchor: ARAnchor? = nil
    var FocusNode: SCNNode? = nil
// 20190712 GT add End//
    
    var bucket_data = [String]()
    // 紀錄當前bucket中內容
    
    var model_data = [String:Array<Float>]()
    // 紀錄最後模型的 scale and rotate
    
    var modal_count = 0
    // 統計放置模型數量
    
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
        
// 20190712 GT add start//
// 加入手勢的初始值//
        sceneView.addGestureRecognizer(UIPinchGestureRecognizer.init(target: self, action: #selector(pinchDo)))//缩放
        sceneView.addGestureRecognizer(UIPanGestureRecognizer.init(target: self, action: #selector(panGuestDo)))//旋轉
        
        // 長按
        sceneView.addGestureRecognizer(UILongPressGestureRecognizer.init(
            target: self,
            action: #selector(longPress(_:))))
        
        
// 20190712 GT add End//
        
        print("start")
        bucket_data_func() // 抓取bucket中內容
        sceneView.delegate = self
        addTapGestureToSceneView() //偵測點擊動作
        configureLighting() // 加入真實光源
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
// 20190712 GT add start//
// 加入平移與旋轉判定//
    
    // 觸發長按手勢後 執行的動作
    @objc func longPress(_ recognizer:UILongPressGestureRecognizer) {
        if recognizer.state == .began {
            print("長按開始")
            let number = recognizer.numberOfTouches
            for i in 0..<number {
                let point = recognizer.location(
                    ofTouch: i, in: sceneView)
                let hitTestResults = sceneView.hitTest(point, types: .featurePoint)
                guard let hitTestResult = hitTestResults.first else { return }
                let translation = hitTestResult.worldTransform.translation
                
                print(
                    "第 \(i + 1) 指的位置：\((translation))")
                setLabel(text:"已選取第 \(i + 1) 指的位置：\((translation))")
                
                if Data_anchor.count != 0{
                    var minDis = Distance(num1: translation, num2: Data_anchor[0].transform.translation)
                    FocusAnchor = Data_anchor[0]
                    FocusNode = Data_Node[0]
                    var number = 0
                    // 鎖定手指最近模型
                    for j in Data_anchor{
                        if minDis > Distance(num1: translation, num2: j.transform.translation)
                        {
                            minDis = Distance(num1: translation, num2: j.transform.translation)
                            FocusAnchor = j
                            FocusNode = Data_Node[number]
                        }
                        number += 1
                    }
                }
            }
        } else if recognizer.state == .ended {
            print("長按結束")
            print("FocusNode",FocusNode as Any)
            print("FocusAnchor",FocusAnchor as Any)
        }
        
    }
    
    func Distance(num1:float3 , num2:float3) -> Double{
        // 計算距離
        let dis1 = pow(num1[0] - num2[0],2)
        let dis2 = pow(num1[1] - num2[1],2)
        let dis3 = pow(num1[2] - num2[2],2)
        return Double(sqrt(dis1+dis2+dis3))
        
    }
    

    @objc func pinchDo(_ pinch: UIPinchGestureRecognizer) {//捏合缩放
        guard let curObjNode = FocusNode else { return }
        let curObj = FocusAnchor
        
        
        if pinch.state == .began {//每次捏合手势开始重新获取
            beginPinchScale = pinch.scale//手势开始时获取当前模型的scale
            beginObjScale = curObjNode.scale.x//手势开始时获取手势的比例scale
        }
        
        if pinch.state == .changed {
            //计算, 当前手势scale除以手势开始时的scale, 以开始时模型的scale为基准相乘, 实现圆润的放大缩小效果
            var scale = beginObjScale*Float(pinch.scale/beginPinchScale)
            scale = scale<0.5 ? 0.5 : scale
            scale = scale>2 ? 2 : scale
            curObjNode.scale = SCNVector3(scale, scale, scale)
            model_data[curObj!.name!] = [scale, scale, scale, model_data[curObj!.name!]![3]]
        }
    }

    @objc func panGuestDo(_ GG: UIPanGestureRecognizer) {//拖动手势
        guard let curObjNode = FocusNode else { return }
        let curObj = FocusAnchor
     
     let velocityPoint = GG.velocity(in: sceneView)
     
     switch GG.state {
        case .changed:
            print("rotate start")
            let xx = Float(velocityPoint.x/5000)//支持空白处水平x轴滑动旋转
            let yy = Float(velocityPoint.y/5000)//支持空白处垂直y轴滑动旋转
            curObjNode.rotation.y = 1
            curObjNode.rotation.w += abs(xx) > abs(yy) ? xx : -yy
            print(curObjNode.rotation)
            print(model_data[curObj!.name!])
            model_data[curObj!.name!] = [model_data[curObj!.name!]![0], model_data[curObj!.name!]![1], model_data[curObj!.name!]![2],curObjNode.rotation.w ]
        case .ended:
            return
        default:
            return
        }
    }

// 20190712 GT add End//
    
//[start-20190628-GT0001-add]//
// 設計跳出視窗 請使用者輸入想要download的檔案名
    @IBAction func button(_ sender: UIButton) {
        let test = name_alert()
    }
//[end---20190628-GT0001-add]//
// start 20190701 GT add//
//設計跳出視窗 選擇要的模型
    @IBAction func button_choose(_ sender: UIButton)
    {
        let queue1 = DispatchQueue(label: "com.appcoda.queue1", qos: DispatchQoS.userInitiated)
        queue1.sync {
            self.choose_alert()
        }
    }
    func choose_alert(){
        let controller = UIAlertController(title: "選擇要放置的模型", message: "", preferredStyle: .actionSheet)
        let names = putData.keys
        var number = "no"
        for name in names {
            let action = UIAlertAction(title: name, style: .default) { (action) in
                number = String(action.title!)
                print(number)
                self.choose = number
                print(self.choose)
                self.final_url = self.download_model()
            }
            controller.addAction(action)
        }
        let cancelAction = UIAlertAction(title: "取消", style: .cancel, handler: nil)
        controller.addAction(cancelAction)
        present(controller, animated: true, completion: nil)
    }
// End 20190701 GT add//

// 20190715 GT add Start
// 抓取bucket中內容
    func bucket_data_func()
    {
        print("bucket_data() start")
        let queue1 = DispatchQueue(label: "com.appcoda.myqueue" ,qos: DispatchQoS.userInteractive)
        let queue2 = DispatchQueue(label: "com.appcoda.myqueue")
        
        let accessKey = "AKIA37LQEHK2R7UNMHM2"
        let secretKey = "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"
        
        let credentialsProvider = AWSStaticCredentialsProvider(accessKey: accessKey, secretKey: secretKey)
        let configuration = AWSServiceConfiguration(region: AWSRegionType.APNortheast1, credentialsProvider: credentialsProvider)
        AWSServiceManager.default().defaultServiceConfiguration = configuration
        
        AWSS3.register(with: configuration!, forKey: "defaultKey")
        let s3 = AWSS3.s3(forKey: "defaultKey")
        
        let listRequest: AWSS3ListObjectsRequest = AWSS3ListObjectsRequest()
        
        queue1.async {
            listRequest.bucket = "howtest.bk"
            listRequest.prefix = "GTtest_arkit_model"
            
        }

        queue2.async{
            
            s3.listObjects(listRequest).continueWith { (task) -> AnyObject? in
                if let error = task.error {
                    print("listObjects failed: [\(error)]")
                }
                else{
                    print("listObjects succeeded")
                    for object in (task.result?.contents)! {
                        
                        print("Object key = \(object.key!)")
                        self.bucket_data.append(object.key!)
                        //print(object.key!.contains("cup.scn"))
                    }
                }
                return nil
            }
        }
        print("done")
    }
// 20190715 GT add End
    
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
    @IBAction func saveBarButtonItemDidTouch(_ sender: UIButton)
    {
        print("save map start")
        sceneView.session.getCurrentWorldMap { (worldMap, error) in
            guard let worldMap = worldMap else {
                return self.setLabel(text: "Error getting current world map.")
            }
            do
            {
                try self.archive(worldMap: worldMap)
                DispatchQueue.main.async
                    {
                    self.setLabel(text: "World map is saved.")
                        print("i am worldanchor",worldMap.anchors)
                        self.upload_worldMap()
                }
            }
            catch
            {
                fatalError("Error saving world map: \(error.localizedDescription)")
            }
        }
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
        isLoadingState = true
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

    
// Start 20190708 GT add//
// Download model in cellphone//
    func download_model() -> URL{
        let accessKey = "AKIA37LQEHK2R7UNMHM2"
        let secretKey = "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"

        let docUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        var url:URL? = nil
        
        if self.choose != "test"{
            url = docUrl.appendingPathComponent(self.choose+".scn")
            print("start model download_model")
            setLabel(text:"start model download_model")
            print(url)
        }
        else{
            url = docUrl.appendingPathComponent(self.choose+".mp4")
            print("start mp4 download_model")
            setLabel(text:"start mp4 download_model")
            print(url)
        }

        
        let credentialsProvider = AWSStaticCredentialsProvider(accessKey: accessKey, secretKey: secretKey)
        let configuration = AWSServiceConfiguration(region: AWSRegionType.APNortheast1, credentialsProvider: credentialsProvider)
        AWSServiceManager.default().defaultServiceConfiguration = configuration
        
        let expression = AWSS3TransferUtilityDownloadExpression()
        expression.progressBlock = {(task, progress) in
            DispatchQueue.main.async(execute: {
            })
        }
        var completionHandler : AWSS3TransferUtilityDownloadCompletionHandlerBlock? = { (task, location, data, error) -> Void in
            DispatchQueue.main.async(execute: {
                if error != nil {
                    print("localizedDescription: \(error!.localizedDescription)")
                    NSLog("Failed with error: \(error)")
                }
                else{
                    self.setLabel(text:"done")
                    NSLog("done")
                }
            })
        }

        let TransferUtility = AWSS3TransferUtility.default()
        let S3BucketName = "howtest.bk/GTtest_arkit_model"
        
        if self.choose != "test"{
            TransferUtility.download(
                to : url!,
                bucket: S3BucketName,
                key: self.choose+".scn",
                expression: expression,
                completionHandler: completionHandler).continueWith { (task) -> AnyObject? in
                    
                    
                    if let error = task.error {
                        NSLog("Error: %@",error.localizedDescription);
                    }
                    if let _ = task.result {
                        NSLog("Download Starting!")
                        // Do something with uploadTask.
                    }
                    return nil;
            }
        }
        else{
            TransferUtility.download(
                to : url!,
                bucket: S3BucketName,
                key: self.choose+".mp4",
                expression: expression,
                completionHandler: completionHandler).continueWith { (task) -> AnyObject? in
                    
                    
                    if let error = task.error {
                        NSLog("Error: %@",error.localizedDescription);
                    }
                    if let _ = task.result {
                        NSLog("Download Starting!")
                        // Do something with uploadTask.
                    }
                    return nil;
            }
        }
        return url!
    }
    
    
// Start 20190703 GT add//
//upload worldMap//
    func upload_worldMap()
    {
        let accessKey = "AKIA37LQEHK2R7UNMHM2"
        let secretKey = "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"
        let credentialsProvider = AWSStaticCredentialsProvider(accessKey: accessKey, secretKey: secretKey)
        let configuration = AWSServiceConfiguration(region: AWSRegionType.APNortheast1, credentialsProvider: credentialsProvider)
        AWSServiceManager.default().defaultServiceConfiguration = configuration
        
        var completionHandler : AWSS3TransferUtilityUploadCompletionHandlerBlock? =
        { (task, error) -> Void in
            if ((error) != nil)
            {
                print("Upload failed")
                print(error)
            }
            else
            {
                print("File uploaded successfully")
                self.setLabel(text:"File uploaded successfully")
            }
        }
        let expression:AWSS3TransferUtilityUploadExpression = AWSS3TransferUtilityUploadExpression()
        let manager = FileManager.default
        let urlForDocument = manager.urls(for: .documentDirectory, in:.userDomainMask)
        let url = urlForDocument[0] as URL
        print(url)
        let contentsOfPath = try? manager.contentsOfDirectory(atPath: url.path)
        print("contentsOfPath: \(contentsOfPath)")
        
        let TransferUtility = AWSS3TransferUtility.default()
        let remoteName_world = "worldmap"
        let S3BucketName = "howtest.bk/GTtest_arkit_model"
        TransferUtility.uploadFile(URL(string: url.absoluteString + "worldMapURL")!,bucket: S3BucketName, key: remoteName_world, contentType: "text/html; charset=utf-8", expression: expression, completionHandler: completionHandler).continueWith(block: { (task: AWSTask) -> Any? in
            if let error = task.error {
                print("Upload failed with error: (\(error.localizedDescription))")
            }
            if(task.description != nil){
                print("Exception uploading thumbnail: \(task.description)")
            }
            if task.result != nil {
                print("Starting upload...")
                self.setLabel(text: "Starting upload...")
            }
            return nil
        })
        let dictToSave = NSDictionary(dictionary: model_data)
        let filePath = NSTemporaryDirectory() + "model_data.txt"
        dictToSave.write(toFile: filePath, atomically: true)
        let remoteName_data = "model_data"
        TransferUtility.uploadFile(URL(string: filePath)!,bucket: "howtest.bk/GTtest_arkit_model", key: remoteName_data, contentType: "text/html; charset=utf-8", expression: expression, completionHandler: completionHandler).continueWith(block: { (task: AWSTask) -> Any? in
            if let error = task.error {
                print("Upload failed with error: (\(error.localizedDescription))")
            }
            if(task.description != nil){
                print("Exception uploading thumbnail: \(task.description)")
            }
            if task.result != nil {
            }
            return nil
        })
        
    }
    
// End 20190703 GT add//
//[start-20190628-GT0003-add]//
// 回傳使用者輸入的資料
    func name_alert() ->String{
        let alert = UIAlertController(title: "輸入名稱", message: "請輸入要下載名稱", preferredStyle: .alert)
        alert.addTextField { (textField) in
            textField.placeholder = "名稱"
            textField.keyboardType = UIKeyboardType.default
            
        }
        let okAction = UIAlertAction(title: "OK", style: .default) { (_) in
            let name:String! = alert.textFields?[0].text
            print(name)
            //print("https://s3-ap-northeast-1.amazonaws.com/howtest.bk/GTtest_arkit_model/"+name+".scn")
            self.wait_print(text: name)
        }
        alert.addAction(okAction)
        let cancelAction = UIAlertAction(title: "取消", style: .cancel, handler: nil)
        alert.addAction(cancelAction)
        present(alert, animated: true, completion: nil)
        return (alert.textFields?[0].text)!
    }
//[end---20190628-GT0003-add]//

//[start-20190628-GT0004-add]//
// 判斷文字是否為空白
    func wait_print(text:String){
        var countnumber = 0
        if text.isEmpty{
            print("sorry, this is empty")
        }
        else{
            for object in self.bucket_data {
                if object.contains(text){
                    countnumber += 1
                    print("I am text "+text)
                }
                
            }
            if countnumber != 0{
                
            print("I am text "+text)
                if text != "test"{
                    self.putData[text] = ("https://s3-ap-northeast-1.amazonaws.com/howtest.bk/GTtest_arkit_model/"+text+".scn")
                }
                else{
                    self.putData[text] = ("https://s3-ap-northeast-1.amazonaws.com/howtest.bk/GTtest_arkit_model/"+text+".mp4")
                }
            }
            else{
                setLabel(text:  "it doesnot contain it")
            }
        }
    }
//[end---20190628-GT0004-add]//
//    func setUpSceneView() {
//        let configuration = ARWorldTrackingConfiguration()
//        configuration.planeDetection = .horizontal
//        sceneView.session.run(configuration)
//
//        sceneView.delegate = self
//        sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]
//    }
//    
    func configureLighting() {
        sceneView.autoenablesDefaultLighting = true
        sceneView.automaticallyUpdatesLighting = true
    }
    

    @objc func addShipToSceneView(withGestureRecognizer recognizer: UIGestureRecognizer) {
        isLoadingState = false
        let tapLocation = recognizer.location(in: sceneView)
        let hitTestResults = sceneView.hitTest(tapLocation, types: .featurePoint)
        // 決定物品可以放在特徵點上而不是平面上
        
        guard let hitTestResult = hitTestResults.first else { return }
        let translation = hitTestResult.worldTransform.translation
        let x = translation.x
        let y = translation.y
        let z = translation.z
        
//[start-20190628-GT0002-mod]//
// 讀取s3 檔案並在一個scene有多個模型
        let fileURL = self.final_url
        if self.choose != "test"{
        do {
            let scene = try SCNScene(url: fileURL! , options: nil)
            print(fileURL)
            print("test2")
            print(self.putData)
            // Set the scene to the view
            print("test3")
            let anchor = ARAnchor(name:self.choose+String(modal_count),transform: hitTestResult.worldTransform)
            sceneView.session.add(anchor: anchor)
            let shipNode = scene.rootNode.childNode(withName: self.choose, recursively: false)!
            shipNode.position = SCNVector3(x,y,z)
            shipNode.scale = SCNVector3(0.5,0.5,0.5)
            shipNode.rotation.y = 1
            shipNode.rotation.w = .pi
            model_data[self.choose+String(modal_count)] = [0.5,0.5,0.5,.pi]
            sceneView.scene.rootNode.addChildNode(shipNode)
            print("i am model_data",model_data )
            print(model_data[self.choose+String(modal_count)])
            
            Data_anchor.append(anchor)
            Data_Node.append(shipNode)
            
//            print("i am list of data_anchor")
           //print(anchor)
           // SCNMatrix4MakeRotation(<#T##angle: Float##Float#>, <#T##x: Float##Float#>, <#T##y: Float##Float#>, <#T##z: Float##Float#>)
            //print(anchor)
//
            print("i am Node")
            print(shipNode)
            print(shipNode.rotation)
            //print("?????????",shipNode.geometry)
        } catch {
            print("ERROR loading scene")
        }
        }
        else{
//20190715 GT add Start
// 放置影片
            let videoItem = AVPlayerItem(url: fileURL!)
            
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
            backgroundNode.position = SCNVector3(x,y,z)
            backgroundNode.scale = SCNVector3(0.5,0.5,0.5)
            model_data[self.choose+String(modal_count)] = [0.5,0.5,0.5,0]
            print("test1")
            let anchor = ARAnchor(name:self.choose+String(modal_count),transform: hitTestResult.worldTransform)
            sceneView.session.add(anchor: anchor)
            sceneView.scene.rootNode.addChildNode(backgroundNode)
            print("test2")
            print("i am backgroundNode",backgroundNode)
            
            Data_anchor.append(anchor)
            Data_Node.append(backgroundNode)
//20190715 GT add End
        }
        modal_count = modal_count+1
        
    }
//[End-20190628-GT0002-mod]//
    func addTapGestureToSceneView() {
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(ViewController.addShipToSceneView(withGestureRecognizer:)))
        sceneView.addGestureRecognizer(tapGestureRecognizer)
    }
    
}


extension float4x4 {
    var translation: float3 {
        let translation = self.columns.3
        return float3(translation.x, translation.y, translation.z)
    }
}

extension UIColor {
    open class var transparentLightBlue: UIColor {
        return UIColor(red: 90/255, green: 200/255, blue: 250/255, alpha: 0.50)
    }
}
// 偵測平面 start
extension ViewController: ARSCNViewDelegate {
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
// 20190710 GT mod//
// 判斷ANchor name來放模型，若無，則放平面
        print("i an anchor",anchor)
        print(isLoadingState)
        if isLoadingState{
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
