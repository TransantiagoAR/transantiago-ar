//
//  PopupView.swift
//  transantiago-ar
//
//  Created by Nicolás Gebauer on 16-11-17.
//  Copyright © 2017 Nicolás Gebauer. All rights reserved.
//

import UIKit

//let PopUpViewItemCellIdentifier = "PopUpViewItemCellIdentifier"

struct PopUpViewItem {
  let name: String
  let eta: [String]
  let color: UIColor
}

let PopupTableViewCellId = "asdasdasd"

class PopupTableView: UITableView, UITableViewDelegate, UITableViewDataSource {
  
  let items: [PopUpViewItem]
  
  init(items: [PopUpViewItem]) {
    let frame = CGRect(x: 0, y: 0, width: 150, height: items.count * 52)
    self.items = items
    super.init(frame: frame, style: .plain)
    self.delegate = self
    self.dataSource = self
  }
  
  required init?(coder aDecoder: NSCoder) {
    items = []
    super.init(coder: aDecoder)
  }
  
  public func image() -> UIImage {
    UIGraphicsBeginImageContextWithOptions(self.bounds.size, false, 0.0)
    self.drawHierarchy(in: self.bounds, afterScreenUpdates: true)
    let image = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    return image ?? UIImage()
  }

  //  MARK: - UITableViewDataSource
  
  func numberOfSections(in tableView: UITableView) -> Int {
    return 1
  }
  
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return items.count
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let item = items[indexPath.row]
    let cell = tableView.dequeueReusableCell(withIdentifier: PopupTableViewCellId) ?? UITableViewCell(style: UITableViewCellStyle.subtitle, reuseIdentifier: PopupTableViewCellId)
    cell.textLabel?.text = item.name
    cell.textLabel?.textColor = item.color
    cell.detailTextLabel?.text = item.eta.count > 0 ? item.eta[0] : "No hay información"
    return cell
  }
  
}

//extension UIImage {
//  convenience init(view: UIView) {
//    UIGraphicsBeginImageContext(view.frame.size)
//    view.layer.render(in:UIGraphicsGetCurrentContext()!)
//    let image = UIGraphicsGetImageFromCurrentImageContext()
//    UIGraphicsEndImageContext()
//    self.init(cgImage: image!.cgImage!)
//  }
//}

