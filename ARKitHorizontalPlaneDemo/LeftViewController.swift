// Slidemenu 沒有使用

import UIKit

class LeftViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let fullScreenSize = UIScreen.main.bounds.size
        
        // 建立 UIPickerView 設置位置及尺寸
        let myPickerView = UIPickerView(frame: CGRect(
            x: 0, y: fullScreenSize.height * 0.3,
            width: fullScreenSize.width * 0.5, height: 150))

        
        let myViewController = LeftUIpickerView()
        
        // 必須將這個 UIViewController 加入
        self.addChildViewController(myViewController)
        
        // 設定 UIPickerView 的 delegate 及 dataSource
        myPickerView.delegate = myViewController
        myPickerView.dataSource = myViewController
        
        // 加入到畫面
        self.view.addSubview(myPickerView)

        // Do any additional setup after loading the view.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
