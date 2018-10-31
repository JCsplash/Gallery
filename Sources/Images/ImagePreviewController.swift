//
//  ImagePreviewController.swift
//  Gallery-iOS
//
//  Created by Jack Chen on 10/31/18.
//  Copyright © 2018 Hyper Interaktiv AS. All rights reserved.
//
import UIKit
class ImagePreviewViewController: UIViewController {
    var isShowingAsPreview: Bool = false
    var image: Image!
    var imageView: UIImageView!
    func dismiss(_ sender: Any?) {
        self.dismiss(animated: true, completion: nil)
    }
    override var prefersStatusBarHidden: Bool {
        return true
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        image.resolve { (UIImage) in
            self.imageView.image = UIImage
        }
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if self.isShowingAsPreview {
            let photoWidth = image.asset.pixelWidth
            let photoHeight = image.asset.pixelHeight
            let viewWidth = self.view.frame.size.width
            let widthAspectRatio = CGFloat(photoWidth) / viewWidth
            let aspectHeight = CGFloat(photoHeight) / widthAspectRatio
            let preferredContentHeight = aspectHeight > 460 ? 460 : aspectHeight
            self.preferredContentSize = CGSize(width: 0, height: preferredContentHeight)
            self.imageView.contentMode = .scaleAspectFill
        }else{
            self.imageView.contentMode = .scaleAspectFit
        }
    }
    private func setupViews(){
        //Init View
        self.view.backgroundColor = UIColor.black
        self.modalTransitionStyle = .crossDissolve
        //Init UIImageView
        imageView = UIImageView()
        self.view.addSubview(imageView)
        imageView.g_pinEdges()
        //Init UIButton
        let button = UIButton()
        button.addTarget(self, action: #selector(dismiss(_:)), for: .touchUpInside)
        self.view.addSubview(button)
        button.g_pinEdges()
    }
}
