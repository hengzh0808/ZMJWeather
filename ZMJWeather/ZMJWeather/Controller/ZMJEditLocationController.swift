//
//  ZMJEditLocationController.swift
//  ZMJWeather
//
//  Created by zhangheng on 2017/6/12.
//  Copyright © 2017年 zhangheng. All rights reserved.
//

import UIKit
import SnapKit

class ZMJEditLocationController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    var deleteAddress:((LocationInfo)->Void)!
    var defaultAddress:((LocationInfo)->Void)!
    var selectAddress:((LocationInfo)->Void)!
    var autoLocation:LocationInfo!
    var manualLocations:Array<LocationInfo>!
    
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.tableFooterView = UIView.init()
        tableView.separatorInset = UIEdgeInsets.init(top: 0, left: 0, bottom: 0, right: 0)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        weak var weakSelf = self
        _ = locationManager.queryAutoLocation(update: true).then(on: DispatchQueue.main, execute: { (location) -> Void in
            weakSelf?.autoLocation = location
            weakSelf?.tableView.reloadData()
        })
        _ = locationManager.queryManualLocations().then(on: DispatchQueue.main, execute: { (locations) -> Void in
            weakSelf?.manualLocations = locations
            weakSelf?.tableView.reloadData()
        })
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if manualLocations == nil {
            return 1
        }
        return manualLocations.count + 1
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44.0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell:UITableViewCell! = tableView.dequeueReusableCell(withIdentifier: "locationCell")
        if cell == nil {
            cell = UITableViewCell.init(style: .default, reuseIdentifier: "locationCell")
            let label = UILabel.init()
            label.textColor = Color115
            label.font = UIFont.systemFont(ofSize: 14.0)
            label.tag = 1001
            cell.contentView.addSubview(label)
            label.snp.makeConstraints({ (make) in
                make.left.equalToSuperview().offset(20.0)
                make.centerY.equalToSuperview()
            })
            
            let imageView = UIImageView.init(image: UIImage.init(named: "location_icon"))
            imageView.contentMode = .scaleAspectFit
            imageView.tag = 1002
            cell.contentView.addSubview(imageView)
            imageView.snp.makeConstraints({ (make) in
                make.left.equalTo(label.snp.right).offset(5.0)
                make.centerY.equalToSuperview()
            })
        }
        if indexPath.row == 0 {
            cell.contentView.viewWithTag(1002)?.isHidden = false
            let label:UILabel = cell.contentView.viewWithTag(1001) as! UILabel
            if autoLocation == nil {
                label.text = "定位中"
            } else {
                var address:NSString! = ""
                if (autoLocation.district != nil && NSString.init(string: autoLocation.district).length > 0) {
                    address = address.appending(autoLocation.district) as NSString
                }
                if (autoLocation.city != nil && NSString.init(string: autoLocation.city).length > 0) {
                    address = address.appending((address.length > 0 ? "," : "") +  autoLocation.city) as NSString
                }
                if (autoLocation.province != nil && NSString.init(string: autoLocation.province).length > 0) {
                    address = address.appending((address.length > 0 ? "," : "") +  autoLocation.province) as NSString
                }
                label.text = address as String?
            }
        } else {
            cell.contentView.viewWithTag(1002)?.isHidden = true
            let label:UILabel = cell.contentView.viewWithTag(1001) as! UILabel
            var address:NSString! = ""
            if (manualLocations[indexPath.row - 1].district != nil && NSString.init(string: manualLocations[indexPath.row - 1].district).length > 0) {
                address = address.appending(manualLocations[indexPath.row - 1].district) as NSString
            }
            if (manualLocations[indexPath.row - 1].city != nil && NSString.init(string: manualLocations[indexPath.row - 1].city).length > 0) {
                address = address.appending((address.length > 0 ? "," : "") +  manualLocations[indexPath.row - 1].city) as NSString
            }
            if (manualLocations[indexPath.row - 1].province != nil && NSString.init(string: manualLocations[indexPath.row - 1].province).length > 0) {
                address = address.appending((address.length > 0 ? "," : "") +  manualLocations[indexPath.row - 1].province) as NSString
            }
            label.text = address as String?
        }
        return cell
    }
}
