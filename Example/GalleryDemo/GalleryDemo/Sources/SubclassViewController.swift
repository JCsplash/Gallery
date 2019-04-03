import UIKit
import Gallery
import Lightbox
import AVFoundation
import AVKit

class SubclassViewController: GalleryController, LightboxControllerDismissalDelegate, GalleryControllerDelegate {
  
  override func viewDidLoad() {

    //        Gallery.Config.VideoEditor.maximumDuration = 30.0
    Gallery.Config.tabsToShow =  [.imageTab, .cameraTab, .videoTab]
    Gallery.Config.initialTab = .imageTab
    Gallery.Config.Camera.imageLimit = 20
    super.viewDidLoad()
    self.delegate = self

  }
  
  
  func lightboxControllerWillDismiss(_ controller: LightboxController) {
    print("lightboxControllerWillDismiss Called")
  }
  
  // MARK: - GalleryControllerDelegate
  
  func galleryControllerDidCancel(_ controller: GalleryController) {
    print("galleryControllerDidCancel Called")
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
//  override func viewWillAppear(_ animated: Bool) {
//    super.viewWillAppear(animated)
//    self.navigationController?.setNavigationBarHidden(true, animated: animated)
//  }
//
//  override func viewWillDisappear(_ animated: Bool) {
//    super.viewWillDisappear(animated)
//    self.navigationController?.setNavigationBarHidden(false, animated: animated)
//  }
}

