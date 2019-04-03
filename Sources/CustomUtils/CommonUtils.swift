//
//  CommonUtils.swift
//  FlairTime
//
//  Created by Jack Chen on 7/31/17.
//  Copyright © 2017 Flair Time LLC. All rights reserved.
//

import UIKit

class CommonUtils {
    static func goToAppSettings() {
        DispatchQueue.main.async {
            guard let settingsUrl = URL(string: UIApplicationOpenSettingsURLString) else {
                return
            }
            if UIApplication.shared.canOpenURL(settingsUrl) {
                if #available(iOS 10.0, *) {
                    UIApplication.shared.open(settingsUrl, completionHandler: { (success) in
                        print("Settings opened: \(success)") // Prints true
                    })
                }else{
                    UIApplication.shared.openURL(settingsUrl as URL)
                }
            }
        }
    }
}
