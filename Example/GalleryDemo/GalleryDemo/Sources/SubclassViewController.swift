import UIKit
import Gallery
import Lightbox
import AVFoundation
import AVKit

class SubclassViewController: GalleryController, LightboxControllerDismissalDelegate, GalleryControllerDelegate {
  
  override func viewDidLoad() {

    Gallery.Config.VideoEditor.maximumDuration = 30.0
    Gallery.Config.tabsToShow =  [.imageTab, .cameraTab, .videoTab]
    Gallery.Config.initialTab = .imageTab
    Gallery.Config.Camera.imageLimit = 20
    super.viewDidLoad()
    self.galleryDelegate = self

  }
  
  
  func lightboxControllerWillDismiss(_ controller: LightboxController) {
    print("lightboxControllerWillDismiss Called")
  }
  
  // MARK: - GalleryControllerDelegate
  
  func galleryControllerDidCancel(_ controller: GalleryController) {
    print("galleryControllerDidCancel Called")
    self.dismiss(animated: true, completion: nil)
  }
  func galleryController(_ controller: GalleryController, didSelectMedia images: [Image], video: Video?) {
    print("didSelectMedia Called")
  }
  func galleryController(_ controller: GalleryController, requestLightbox images: [Image]) {
    print("requestLightbox Called")
    return
  }
  func galleryController(_ controller: GalleryController, requestVideoLightbox video: Video) {
    print("requestVideoLightbox Called")
    return
  }
  func galleryController(_ controller: GalleryController, capturedPhoto image: UIImage) {
    print("capturedPhoto Called")
  }
  
  func galleryController(_ controller: GalleryController, capturedVideo videoURL: URL) {
    print("captureVideo Called")
  }
  var isPrefersStatusBarHidden:Bool = false
  override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
    return UIStatusBarAnimation.slide
  }
  override var prefersStatusBarHidden: Bool {
    return isPrefersStatusBarHidden
  }
  override func viewWillAppear(_ animated: Bool) {
    isPrefersStatusBarHidden = true
    UIView.animate(withDuration: 0.5) { () -> Void in
      self.setNeedsStatusBarAppearanceUpdate()
    }
  }
  
  
//
//  override func viewWillDisappear(_ animated: Bool) {
//    super.viewWillDisappear(animated)
//    self.navigationController?.setNavigationBarHidden(false, animated: animated)
//  }
}

