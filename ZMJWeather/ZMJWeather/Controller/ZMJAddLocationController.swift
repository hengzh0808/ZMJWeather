//
//  ZMJAddLocationController.swift
//  ZMJWeather
//
//  Created by zhangheng on 2017/6/12.
//  Copyright © 2017年 zhangheng. All rights reserved.
//

import UIKit
import RxCocoa
import SnapKit

class ZMJAddLocationController: UIViewController {

    var addAddress:((LocationInfo)->Void)!
    var dataViews:Array<UIView> = []
    private let locations:Array<String> = ["北京","上海","天津","重庆","哈尔滨","长春","沈阳","南昌","南京","济南","合肥","石家庄","郑州","武汉","长沙","西安","太原","成都","西宁","海口","广州","贵阳","杭州","福州","台北","兰州","昆明","呼和浩特","银川","乌鲁木齐","拉萨","南宁","香港","澳门"]
    @IBOutlet weak var addressInput: UITextField!
    @IBOutlet weak var addressOutput: UILabel!
    @IBOutlet weak var autoLocationSign: UIImageView!
    @IBOutlet weak var autoLocationLabel: UILabel!
    @IBOutlet weak var deleteInput: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initEvents()
        addLocationViews()
    }
    
    func initEvents() {
        weak var weakSelf = self
        _ = addressInput.rx.text.orEmpty.asObservable().subscribe(onNext: { (text) in
            weakSelf?.deleteInput.isHidden = (text as NSString).length == 0
            if ((text as NSString).length == 0) {
                weakSelf?.addLocationViews()
            }
        })
        
        _ = addressInput.rx.controlEvent(.editingDidEndOnExit).subscribe(onNext: { () in
            locationManager.search(address: (weakSelf?.addressInput.text)!).then(execute: { (locations) -> Void in
                weakSelf?.addSearchResult(locations: locations)
            }).catch(execute: { (error) in
                weakSelf?.addSearchErrorView(error: error as NSError)
            })
        })
        
        locationManager.updateLocation().then { (locationInfo) -> Void in
            weakSelf?.addressOutput.text = locationInfo.city + "，" + locationInfo.district
            weakSelf?.autoLocationLabel.text = "自动定位"
        }.catch { (error) in
            weakSelf?.autoLocationLabel.text = "自动定位失败"
        }
    }
    
    func removeLocations() {
        for view in dataViews {
            view.removeFromSuperview()
        }
    }
    
    func addSearchResult(locations:Array<LocationInfo>) {
        removeLocations()
        for (index, location) in locations.enumerated() {
            let locationLabel = UILabel.init()
            locationLabel.textColor = Color115
            locationLabel.font = UIFont.systemFont(ofSize: 16.0)
            var address:NSString! = ""
            if (location.district != nil) {
                address = address.appending(location.district + ",") as NSString
            }
            if (location.city != nil) {
                address = address.appending(location.city + ",") as NSString
            }
            if (location.province != nil) {
                address = address.appending(location.province) as NSString
            }
            locationLabel.text =  address! as String
            dataViews.append(locationLabel)
            self.view.addSubview(locationLabel)
            locationLabel.snp.makeConstraints({ (make) in
                make.top.equalToSuperview().offset(168 + 44 * index)
                make.left.equalTo(self.addressOutput.snp.left)
                make.height.equalTo(44)
            })
            
            let lineView = UIView.init()
            lineView.backgroundColor = Color229
            dataViews.append(lineView)
            self.view.addSubview(lineView)
            lineView.snp.makeConstraints({ (make) in
                make.top.equalToSuperview().offset(168 + 44 * (index + 1))
                make.left.equalToSuperview()
                make.width.equalToSuperview()
                make.height.equalTo(0.5)
            })
        }
    }
    
    func addSearchErrorView(error:NSError) {
        removeLocations();
        
        let errorLabel =  UILabel.init()
        errorLabel.font = UIFont.systemFont(ofSize: 16.0)
        errorLabel.textColor = Color115
        dataViews.append(errorLabel)
        self.view.addSubview(errorLabel)
        errorLabel.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(168)
            make.left.equalTo(self.addressOutput.snp.left)
            make.height.equalTo(44)
        }
        
        let lineView = UIView.init()
        lineView.backgroundColor = Color229
        dataViews.append(lineView)
        self.view.addSubview(lineView)
        lineView.snp.makeConstraints({ (make) in
            make.top.equalToSuperview().offset(168 + 44)
            make.left.equalToSuperview()
            make.width.equalToSuperview()
            make.height.equalTo(0.5)
        })
    }
    
    func addLocationViews() {
        removeLocations();
        
        for (index, location) in locations.enumerated() {
            let row = index / 5
            let col = index % 5
            let button = UIButton.init(type: .custom)
            button.setTitle(location, for: .normal)
            button.setTitleColor(Color115, for: .normal)
            button.titleLabel?.font = UIFont.systemFont(ofSize: 16.0)
            dataViews.append(button)
            self.view.addSubview(button)
            button.snp.makeConstraints({ (make) in
                make.top.equalToSuperview().offset(168 + 44 * row)
                make.width.equalToSuperview().multipliedBy(0.2)
                make.left.equalToSuperview().offset(UIScreen.main.bounds.width * 0.2 * CGFloat(col))
                make.height.equalTo(44)
            })
            if col == 4 || location == locations.last {
                let lineView = UIView.init()
                lineView.backgroundColor = Color229
                dataViews.append(lineView)
                self.view.addSubview(lineView)
                lineView.snp.makeConstraints({ (make) in
                    make.top.equalToSuperview().offset(168 + 44 * (row + 1))
                    make.left.equalToSuperview()
                    make.width.equalToSuperview()
                    make.height.equalTo(0.5)
                })
            }
        }
    }
    
    @IBAction func backController(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func deleteInputText(_ sender: Any) {
        self.addressInput.text = ""
    }
}
