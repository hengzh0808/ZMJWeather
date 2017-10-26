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
import PromiseKit
import SwiftyJSON

class ZMJAddLocationController: UIViewController {

    var addAddress:((LocationInfo)->Void)!
    var dataViews:Array<UIView> = []
    private var locations:Array<LocationInfo> = []
    @IBOutlet weak var addressInput: UITextField!
    @IBOutlet weak var addressOutput: UILabel!
    @IBOutlet weak var autoLocationSign: UIImageView!
    @IBOutlet weak var autoLocationLabel: UILabel!
    @IBOutlet weak var deleteInput: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initCityData()
        initEvents()
        addLocationViews()
    }
    
    func initCityData() {
        let path = Bundle.main.path(forResource: "City", ofType: "txt")
        do {
            let content = try String(contentsOfFile:path!, encoding: String.Encoding.utf8)
            let json = JSON.init(parseJSON: content)
            let citys = json.arrayObject
            for city in citys! {
                let cityInfo:NSDictionary! = city as! NSDictionary
                let location = LocationInfo.init()
                location.adcode = cityInfo.value(forKey: "adcode") as! String
                location.city = cityInfo.value(forKey: "name") as! String
                location.latitude = (cityInfo.value(forKey: "latitude") as! NSNumber).doubleValue
                location.longitude = (cityInfo.value(forKey: "longitude") as! NSNumber).doubleValue
                locations.append(location)
            }
        } catch {}
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
        locationManager.queryAutoLocation(update: true).then(on: DispatchQueue.main) { (locationInfo) -> Void in
            weakSelf?.addressOutput.text = (locationInfo?.city)! + "，" + (locationInfo?.district)!
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
            let locationButton = UIButton.init(type: .custom)
            locationButton.setTitleColor(Color115, for: .normal)
            locationButton.titleLabel?.font = UIFont.systemFont(ofSize: 16.0)
            var address:NSString! = ""
            if (location.district != nil && NSString.init(string: location.district).length > 0) {
                address = address.appending(location.district) as NSString
            }
            if (location.city != nil && NSString.init(string: location.city).length > 0) {
                address = address.appending((address.length > 0 ? "," : "") + location.city) as NSString
            }
            if (location.province != nil && NSString.init(string: location.province).length > 0) {
                address = address.appending((address.length > 0 ? "," : "") + location.province) as NSString
            }
            locationButton.setTitle(address! as String, for: .normal)
            dataViews.append(locationButton)
            self.view.addSubview(locationButton)
            locationButton.snp.makeConstraints({ (make) in
                make.top.equalToSuperview().offset(168 + 44 * index)
                make.left.equalTo(self.addressOutput.snp.left)
                make.height.equalTo(44)
            })
            
            weak var weakSelf = self
            _ = locationButton.rx.tap.asControlEvent().subscribe(onNext: { () in
                weakSelf?.saveLocation(location: location)
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
            button.setTitle(location.city, for: .normal)
            button.setTitleColor(Color115, for: .normal)
            button.titleLabel?.font = UIFont.systemFont(ofSize: 16.0)
            weak var weakSelf = self
            _ = button.rx.tap.asControlEvent().subscribe(onNext: { () in
                weakSelf?.saveLocation(location: location)
            })
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
    
    func saveLocation(location:LocationInfo) {
        weak var weakSelf = self
        locationManager.saveLocation(location: location, type: .Manual).then(on: DispatchQueue.main, execute: { (result) -> Void in
            weakSelf?.navigationController?.popViewController(animated: true)
        }).catch(on: DispatchQueue.main, execute: { (error) in
            UIAlertView.init(title: nil, message: "当前城市已添加", delegate: nil, cancelButtonTitle: "确认").show()
        })
    }
    
    @IBAction func backController(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func deleteInputText(_ sender: Any) {
        self.addressInput.text = ""
    }
}
