//
//  chooseBuiltWatch.swift
//  ARKitHorizontalPlaneDemo
//
//  Created by GT on 2019/7/10.
//  Copyright © 2019年 Jayven Nhan. All rights reserved.
//

import UIKit

class chooseBuiltWatch:UIViewController{
    var built_ID:String? = nil
    // 紀錄built人的ID
    
//20190710 GT add//
//按下built，輸入使用者ＩＤ
    @IBAction func built(){
        let quene = DispatchQueue(label: "hi", qos: DispatchQoS.userInitiated)
        quene.sync {
            self.built_ID = built_alert()
        }
        
    }
    func built_alert() ->String{
        let alert = UIAlertController(title: "輸入ID", message: "請輸入您的ID", preferredStyle: .alert)
        alert.addTextField { (textField) in
            textField.placeholder = "ID"
            textField.keyboardType = UIKeyboardType.default
            
        }
        let okAction = UIAlertAction(title: "OK", style: .default) { (_) in
            print("WTF")
            if (alert.textFields?[0].text)! == "GT"{
                if let controller = self.storyboard?.instantiateViewController(withIdentifier: "built") {
                    self.present(controller, animated: true, completion: nil)
                }
            }
            else{
                print("fail")
            }
        }
        alert.addAction(okAction)
        let cancelAction = UIAlertAction(title: "取消", style: .cancel, handler: nil)
        alert.addAction(cancelAction)
        present(alert, animated: true, completion: nil)
        return (alert.textFields?[0].text)!
    }
//20190710 GT end//
//20190710 GT add//
//按下watch，輸入使用者ＩＤ
    @IBAction func watch(){
        let quene = DispatchQueue(label: "hi", qos: DispatchQoS.userInitiated)
        quene.sync {
            self.built_ID = watch_alert()
        }
        
    }
    func watch_alert() ->String{
        let alert = UIAlertController(title: "輸入ID", message: "請輸入您的ID", preferredStyle: .alert)
        alert.addTextField { (textField) in
            textField.placeholder = "ID"
            textField.keyboardType = UIKeyboardType.default
            
        }
        let okAction = UIAlertAction(title: "OK", style: .default) { (_) in
            print("WTF")
            if (alert.textFields?[0].text)! == "GT"{
                if let controller = self.storyboard?.instantiateViewController(withIdentifier: "watch") {
                    self.present(controller, animated: true, completion: nil)
                }
            }
            else{
                print("fail")
            }
        }
        alert.addAction(okAction)
        let cancelAction = UIAlertAction(title: "取消", style: .cancel, handler: nil)
        alert.addAction(cancelAction)
        present(alert, animated: true, completion: nil)
        return (alert.textFields?[0].text)!
    }
//20190710 GT end//
}
