//
//  DialogManager.swift
//  Pods
//
//  Created by Dan Trenz on 2/5/16.
//
//

import Foundation

protocol Dialogable {
  var message: String { get }
}

class DialogManager {

  typealias RememberableDialogSubject = Dialogable & Rememberable

  enum DialogType {
    case alert(blocking: Bool)
    case optionalUpdate(updateURL: NSURL)
    case requiredUpdate(updateURL: NSURL)
  }

  func displayAlertDialog(alertConfig: RememberableDialogSubject, blocking: Bool) {
    let dialog = createAlertController(type: .alert(blocking: blocking), message: alertConfig.message)

    displayAlertController(alert: dialog) { () -> Void in
      if !blocking {
        Memory.remember(item: alertConfig)
      }
    }
  }

  func displayRequiredUpdateDialog(updateConfig: Dialogable, updateURL: NSURL) {
    let dialog = createAlertController(type: .requiredUpdate(updateURL: updateURL), message: updateConfig.message)

    displayAlertController(alert: dialog, completion: nil)
  }

  func displayOptionalUpdateDialog(updateConfig: RememberableDialogSubject, updateURL: NSURL) {
    let dialog = createAlertController(type: .optionalUpdate(updateURL: updateURL), message: updateConfig.message)

    displayAlertController(alert: dialog) { () -> Void in
        Memory.remember(item: updateConfig)
    }
  }

  // MARK: Custom Alert Controllers

  func createAlertController(type: DialogType, message: String) -> UIAlertController {
    let alertController = UIAlertController(title: nil, message: message, preferredStyle: .alert)

    switch type {
    case let .alert(blocking):
        if !blocking {
          alertController.addAction(dismissActon())
        }

    case let .optionalUpdate(updateURL):
        alertController.addAction(dismissActon())
        alertController.addAction(updateAction(updateURL: updateURL))

    case let .requiredUpdate(updateURL):
        alertController.addAction(updateAction(updateURL: updateURL))
    }

    return alertController
  }

    func displayAlertController(alert: UIAlertController, completion: (() -> Void)?) {
        DispatchQueue.main.async {
            if let topViewController = self.topViewController() {
                topViewController.present(alert, animated: true) {
                    if let completion = completion {
                        completion()
                    }
                }
            }
        }
    }

  func topViewController() -> UIViewController? {
    return UIApplication.shared.keyWindow?.rootViewController
  }

  // MARK: Custom Alert Actions

  private func dismissActon() -> UIAlertAction {
    return UIAlertAction(
        title: NSLocalizedString("Dismiss", comment: "Button title for dismissing the update AlertView"),
        style: .default) { _ in }
  }

  private func updateAction(updateURL: NSURL) -> UIAlertAction {
    return UIAlertAction(
        title: NSLocalizedString("Update", comment: "Button title for accepting the update AlertView"),
        style: .default) { (_) -> Void in
            if UIApplication.shared.canOpenURL(updateURL as URL) {
                DispatchQueue.main.async {
                    UIApplication.shared.openURL(updateURL as URL)
                }
            }
        }
  }

}
