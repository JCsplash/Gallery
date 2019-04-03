//
//  AlertService.swift
//  FlairTime
//
//  Created by Jack Chen on 8/2/17.
//  Copyright © 2017 Flair Time LLC. All rights reserved.
//

import PromiseKit
import FCAlertView


class AlertUtils: NSObject, FCAlertViewDelegate{
    static var BTN_DONE = -1
    static var BTN_1 = 0
    static var BTN_2 = 1
    
    static func showFCAlert(title: String? = nil, subtitle: String!, image: UIImage? = nil, doneTitle: String? = nil, buttons: [Any]? = nil, colorScheme: UIColor? = nil){
        let alert = FCAlertView()
        if let _ = colorScheme {
            alert.colorScheme = colorScheme
        }
        alert.showAlert(withTitle: title, withSubtitle: subtitle, withCustomImage: image, withDoneButtonTitle: doneTitle, andButtons: buttons)
    }
    
    static func showFCAlertP(title: String? = nil, subtitle: String!, image: UIImage? = nil, doneTitle: String? = nil, buttons: [Any]? = nil, colorScheme: UIColor? = nil) -> Promise<Int> {
        let proxy = AlertServiceDelegate()
        proxy.retainCycle = proxy
        let alert = FCAlertView()
        if let _ = colorScheme {
            alert.colorScheme = colorScheme
        }
        alert.delegate = proxy
        alert.showAlert(withTitle: title, withSubtitle: subtitle, withCustomImage: image, withDoneButtonTitle: doneTitle, andButtons: buttons)
        return proxy.promise
    }
}

private class AlertServiceDelegate: NSObject, FCAlertViewDelegate {
    let (promise, fulfill, reject) = Promise<Int>.pending()
    var retainCycle: NSObject?
    
    func fcAlertView(_ alertView: FCAlertView, clickedButtonIndex index: Int, buttonTitle title: String) {
        fulfill(index)
        retainCycle = nil
    }
    func fcAlertDoneButtonClicked(_ alertView: FCAlertView){
        fulfill(-1)
        retainCycle = nil
    }
}










