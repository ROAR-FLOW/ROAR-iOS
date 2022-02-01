//
//  ARPhoto2PopupViewController.swift
//  IntelRacing
//
//  Created by Michael Wu on 9/26/21.
//

import Foundation
import UIKit
import SwiftUI
class ARPhoto2PopupViewController: UIViewController {
    weak var selectContentDelegate: SelectContentDelegate?
    @IBOutlet weak var uiTableView: UITableView!
    var dataSources: [[String]] = [];
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        self.uiTableView.delegate = self
        self.uiTableView.dataSource = self
        self.uiTableView.reloadData()
        dataSources = [
            ["Submarine", "models.scnassets/Nautilus_Submarine.usdz"],
            ["Warrior", "models.scnassets/Sci-fi_Warrior.usdz"],
            ["Blade","models.scnassets/Cyberpunk_Blade.usdz"],
            ["dragon","models.scnassets/dragon.usdz"],
            ["book","models.scnassets/Medieval_Fantasy_Book.usdz"],
            ["sniper","models.scnassets/sniper.usdz"],
            ["parade","models.scnassets/The_Parade_Armour_of_King_Erik_XIV_of_Sweden.usdz"],
            ["tiger","models.scnassets/tiger.usdz"],
            ["airplane","models.scnassets/turtlebot.usdz"]
        ]
    }
    
    
    func showAnimate()
    {
        self.view.transform = CGAffineTransform(scaleX: 1.3, y: 1.3)
        self.view.alpha = 0.0;
        UIView.animate(withDuration: 0.25, animations: {
            self.view.alpha = 1.0
            self.view.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
        });
    }
    
    func removeAnimate()
    {
        UIView.animate(withDuration: 0.25, animations: {
            self.view.transform = CGAffineTransform(scaleX: 1.3, y: 1.3)
            self.view.alpha = 0.0;
            }, completion:{(finished : Bool)  in
                if (finished)
                {
                    self.view.removeFromSuperview()
                }
        });
    }
}

extension ARPhoto2PopupViewController: UITableViewDelegate, UITableViewDataSource{
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell:UITableViewCell=UITableViewCell(style: .default, reuseIdentifier: "mycell")
        cell.textLabel?.text = dataSources[indexPath.row][0]
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.dismiss(animated: true, completion: {
            let filePath = self.dataSources[indexPath.row][1]
            let name = self.dataSources[indexPath.row][0]
            self.selectContentDelegate?.onContentSelectionMade(filePath: filePath, name: name)
        }
)
    }
    
    func tableView(_ tableView:UITableView, numberOfRowsInSection section:Int) -> Int
        {
            return dataSources.count
        }
}
