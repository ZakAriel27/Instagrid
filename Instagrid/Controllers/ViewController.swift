//
//  ViewController.swift
//  InstagridDraft
//
//  Created by Pascal Diamand on 11/10/2020.
//  Copyright © 2020 Pascal Diamand. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
  var viewOrientation = 0         // Orientation rawValue
  var layoutUsed      = 0         // layout to be displayed
  var frameFilling    = 0         // Calculated value to know boxes containing a photo
  var tagBox          = 0         // Tag corresponding to the button pressed (image box)
  var iTag            = [0,0,0,0] // Indirection between tags and indexes
  
  let imagePicker     = UIImagePickerController()

  @IBOutlet var       photoButtons: [UIButton]!   // Table of buttons in the layout displayed
  @IBOutlet weak var  photoView: UIView!          // View corresponding to the layout and photos displayed
 // @IBOutlet var       photos: [UIImageView]!      // ?
  @IBOutlet var       layoutButtons: [UIButton]!  // Table of buttons corresponding to the 3 layout models
  @IBOutlet weak var  swipeLabel: UILabel!        // Swipe Label
  
  @IBAction func layoutChoice(_ sender: UIButton) {
    layoutChosen(sender.tag)
  }
  
  @IBAction func boxChoice(_ sender: UIButton) {
    tagBox = sender.tag
    boxChosen()
  }
  
  // MARK: View Events
  
  override func viewDidLoad() {
    super.viewDidLoad()
    imagePicker.delegate = self
    let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(swipePhotoView(_:)))
    photoView.addGestureRecognizer(panGestureRecognizer)
    tagOrder()
    orientationUpdate()
    layoutChosen(0)
  }

  override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
    coordinator.animate(alongsideTransition:
      { (UIViewControllerTransitionCoordinatorContext) -> Void in
        self.orientationUpdate()
        self.layoutChosen(self.layoutUsed)
      }, completion: { (UIViewControllerTransitionCoordinatorContext) -> Void in
    })
    super.viewWillTransition(to: size, with: coordinator)
  }
  
  // Need to adjust tag value as button order given by xCode can't be predicted
  func tagOrder() {
    for index in 0...photoButtons.count - 1 {
      iTag[photoButtons[index].tag] = index
    }
  }
  
  // Adjust Swipe label according to orientation
  func orientationUpdate() {
    viewOrientation = UIApplication.shared.statusBarOrientation.rawValue
    swipeLabel.text = viewOrientation < 3 ? "Swipe Up to share" : "Swipe Left to share"
  }

  // Layout selected by user
  func layoutChosen(_ tag: Int) {
    layoutButtons[layoutUsed].isSelected = false
    layoutUsed = tag
    layoutButtons[layoutUsed].isSelected = true
    // Move if necessary and possible photo made invisible
    let frameCase = frameFilling > 0  && layoutUsed < 2 ? layoutUsed*10 + frameFilling : 0
    switch frameCase {
      case  2,7,12,17:
        photoButtons[iTag[0]].setImage(photoButtons[iTag[1]].currentImage, for: UIControl.State.normal)
        photoButtons[iTag[1]].setImage(UIImage(named: "PlusPhoto"), for: UIControl.State.normal)
        frameFilling += 1 - 2
      case  3,8:
        photoButtons[iTag[3]].setImage(photoButtons[iTag[1]].currentImage, for: UIControl.State.normal)
        photoButtons[iTag[1]].setImage(UIImage(named: "PlusPhoto"), for: UIControl.State.normal)
        frameFilling += 10 - 2
      case 13:
        photoButtons[iTag[2]].setImage(photoButtons[iTag[1]].currentImage, for: UIControl.State.normal)
        photoButtons[iTag[1]].setImage(UIImage(named: "PlusPhoto"), for: UIControl.State.normal)
        frameFilling += 5 - 2
      case 20,21,22,23:
        photoButtons[iTag[2]].setImage(photoButtons[iTag[3]].currentImage, for: UIControl.State.normal)
        photoButtons[iTag[3]].setImage(UIImage(named: "PlusPhoto"), for: UIControl.State.normal)
        frameFilling += 5 - 10
      case 25,26:
        photoButtons[iTag[1]].setImage(photoButtons[iTag[3]].currentImage, for: UIControl.State.normal)
        photoButtons[iTag[3]].setImage(UIImage(named: "PlusPhoto"), for: UIControl.State.normal)
        frameFilling += 2 - 10
      case 27:
        photoButtons[iTag[0]].setImage(photoButtons[iTag[3]].currentImage, for: UIControl.State.normal)
        photoButtons[iTag[3]].setImage(UIImage(named: "PlusPhoto"), for: UIControl.State.normal)
        frameFilling += 1 - 10
      default:
        break
    }
    // Show-hide boxes according to the layout choosen
    photoButtons[iTag[1]].isHidden = layoutUsed == 0 ? true : false
    photoButtons[iTag[3]].isHidden = layoutUsed == 1 ? true : false
  }
  
  // Box selected by user
  func boxChosen() {
    imagePicker.allowsEditing = false
    imagePicker.sourceType = .photoLibrary
    present(imagePicker, animated: true, completion: nil)
  }
     
  
  // MARK: - UIImagePickerControllerDelegate Methods
  
  func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
    if let pickedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
      frameFilling += photoButtons[iTag[tagBox]].image(for: UIControl.State.normal)?.description.contains("PlusPhoto") ?? false ? tagBox*tagBox + 1 : 0
      photoButtons[iTag[tagBox]].setImage(pickedImage, for: UIControl.State.normal)
      dismiss(animated: true, completion: nil)
    }
  }

  func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
      dismiss(animated: true, completion: nil)
  }

  
  // MARK: Swipe Event
  
  @objc func swipePhotoView(_ sender: UIPanGestureRecognizer) {
      switch sender.state {
      case .began, .changed:
          translationPhotoView(gesture: sender)
      case .ended, .cancelled:
          animatePhotoView()
      default:
          break
      }
  }
  
  private func translationPhotoView(gesture: UIPanGestureRecognizer) {
    let translation = gesture.translation(in: photoView)
    if viewOrientation < 3 {
      photoView.transform = CGAffineTransform(translationX: 0, y: translation.y)
    } else {
      photoView.transform = CGAffineTransform(translationX: translation.x, y: 0)
    }
  }

  private func animatePhotoView() {
    var translationEnd: CGAffineTransform
    if viewOrientation < 3 {
         translationEnd = CGAffineTransform(translationX: 0, y: -(self.view.frame.height))
    } else {
         translationEnd = CGAffineTransform(translationX: -(self.view.frame.width), y: 0)
    }
    UIView.animate(withDuration: 0.4, animations: {
      self.photoView.transform = translationEnd}, completion: {
        (succes) in
        if (self.frameFilling == 16 && self.layoutUsed == 0) || (self.frameFilling == 8 && self.layoutUsed == 1) || (self.frameFilling == 18 && self.layoutUsed == 2) {
          self.sendPhotoView()
        } else {
          self.showMessage()
        }
    })
  }
  
  func sendPhotoView() {
    let item: [Any] = [viewToImage()] // Retrieves image corresponding to the frame with the selected photos
    let activity = UIActivityViewController(activityItems: item, applicationActivities: nil)
    activity.completionWithItemsHandler = { activity, success, items, error in self.animateBackPhotoView()}
    present(activity, animated: true)
  }

  private func viewToImage() -> UIImage {
    let renderer = UIGraphicsImageRenderer(size: photoView.bounds.size)
    return(renderer.image { context in photoView.drawHierarchy(in: photoView.bounds, afterScreenUpdates: true)})
  }
  
  private func showMessage() {
      let alert = UIAlertController(title: "Unfinished Photo frame!", message: "Please, complete it before sending it.", preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Default action"), style: .default, handler: {_ in self.animateBackPhotoView() }))
      self.present(alert, animated: true, completion: nil)
  }
  
  private func animateBackPhotoView() {
   var translationEnd: CGAffineTransform
    if viewOrientation < 3 {
      translationEnd = CGAffineTransform(translationX: 0, y: (self.view.frame.height))
    } else {
      translationEnd = CGAffineTransform(translationX: (self.view.frame.width), y: 0)
    }
    UIView.animate(withDuration: 0.4, animations: {self.photoView.transform = translationEnd}, completion:
      {(succes) in self.springPhotoView()})
  }
  
  func springPhotoView() {
    photoView.transform = CGAffineTransform(scaleX: 0.01, y: 0.01)
    UIView.animate(withDuration: 0.5, delay: 0.0, usingSpringWithDamping: 0.5, initialSpringVelocity: 1
      , options: [] , animations: {self.photoView.transform = .identity}, completion: nil)
  }
}
