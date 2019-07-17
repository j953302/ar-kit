// Slidemenu 沒有使用

import UIKit

class LeftUIpickerView: UIViewController,UIPickerViewDelegate, UIPickerViewDataSource {
    let week = ["a","b","c"]
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    // UIPickerViewDataSource 必須實作的方法：
    // UIPickerView 有幾列可以選擇
    func numberOfComponentsInPickerView(
        pickerView: UIPickerView) -> Int {
        return 2
    }
    // UIPickerViewDataSource 必須實作的方法：
    // UIPickerView 各列有多少行資料
    func pickerView(_ pickerView: UIPickerView,
                    numberOfRowsInComponent component: Int) -> Int {
        // 設置第一列時
            // 返回陣列 week 的成員數量
            return week.count
        }

    // UIPickerView 每個選項顯示的資料
    func pickerView(_ pickerView: UIPickerView,
                    titleForRow row: Int, forComponent component: Int)
        -> String? {
            // 設置第一列時
                return week[row]
        }
}

    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */
