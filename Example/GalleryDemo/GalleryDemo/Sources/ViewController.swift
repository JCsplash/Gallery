import UIKit
import Gallery
import Lightbox
import AVFoundation
import AVKit

class ViewController: UIViewController {
  var button: UIButton!
  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = UIColor.white
    button = UIButton(type: .system)
    button.frame.size = CGSize(width: 200, height: 50)
    button.setTitle("Open Gallery", for: UIControlState())
    button.addTarget(self, action: #selector(buttonTouched(_:)), for: .touchUpInside)
    view.addSubview(button)
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    button.center = CGPoint(x: view.bounds.size.width/2, y: view.bounds.size.height/2)
  }

  func buttonTouched(_ button: UIButton) {
    let anotherVC = SubclassViewController()
    present(anotherVC, animated: true, completion: nil)
  }
}

