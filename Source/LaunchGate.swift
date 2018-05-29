//
//  LaunchGate.swift
//  Pods
//
//  Created by Dan Trenz on 1/19/16.
//
//

import Foundation

/// Custom internal error type
typealias LaunchGateError = Error & CustomStringConvertible

public class LaunchGate {

  /// Parser to use when parsing the configuration file
  public var parser: LaunchGateParser!

  /// URI for the configuration file
  var configurationFileURL: NSURL!

  /// App Store URI ("itms-apps://itunes.apple.com/...") for the current app
  var updateURL: NSURL!

  /// Manager object for the various alert dialogs
  var dialogManager: DialogManager!

  // MARK: - Public API

  /**
  Failable initializer. If either the `configURI` or `appStoreURI` are unable to be
  converted into an `NSURL` (i.e. containing illegal URL characters) this initializer
  will return `nil`.

  - Parameters:
    - configURI: URI for the configuration file
    - appStoreURI: App Store URI ("itms-apps://itunes.apple.com/...") for the current app

  - Returns: A `LaunchGate` instance or `nil`
  */
  public init?(configURI: String, appStoreURI: String) {
    guard let configURL = NSURL(string: configURI) else { return nil }
    guard let appStoreURL = NSURL(string: appStoreURI) else { return nil }

    configurationFileURL = configURL
    updateURL = appStoreURL
    parser = DefaultParser()
    dialogManager = DialogManager()
  }

  /// Check the configuration file and perform any appropriate action.
  public func check() {
    performCheck(remoteFileManager: RemoteFileManager(remoteFileURL: configurationFileURL))
  }

  // MARK: - Internal API

  /**
  Check the configuration file and perform any appropriate action, using
  the provided `RemoteFileManager`.

  - Parameter remoteFileManager: The `RemoteFileManager` to use to fetch the configuration file.
  */
  func performCheck(remoteFileManager: RemoteFileManager) {
    remoteFileManager.fetchRemoteFile { (jsonData) -> Void in
        if let config = self.parser.parse(jsonData: jsonData) {
            self.displayDialogIfNecessary(config: config, dialogManager: self.dialogManager)
      }
    }
  }

  /**
   Determine which dialog, if any, to display based on the parsed configuration.

   - Parameters:
     - config:        Configuration parsed from remote configuration file.
     - dialogManager: Manager object for the various alert dialogs
   */
  func displayDialogIfNecessary(config: LaunchGateConfiguration, dialogManager: DialogManager) {
    if let reqUpdate = config.requiredUpdate, let appVersion = currentAppVersion() {
        if shouldShowRequiredUpdateDialog(updateConfig: reqUpdate, appVersion: appVersion) {
            dialogManager.displayRequiredUpdateDialog(updateConfig: reqUpdate, updateURL: updateURL)
      }
    } else if let optUpdate = config.optionalUpdate, let appVersion = currentAppVersion() {
        if shouldShowOptionalUpdateDialog(updateConfig: optUpdate, appVersion: appVersion) {
            dialogManager.displayOptionalUpdateDialog(updateConfig: optUpdate, updateURL: updateURL)
      }
    } else if let alert = config.alert {
        if shouldShowAlertDialog(alertConfig: alert) {
            dialogManager.displayAlertDialog(alertConfig: alert, blocking: alert.blocking)
      }
    }
  }

  /**
   Determine if an alert dialog should be displayed, based on the configuration.

   - Parameter alertConfig: An `AlertConfiguration`, parsed from the configuration file.

   - Returns: `true`, if an alert dialog should be displayed; `false`, if not.
   */
  func shouldShowAlertDialog(alertConfig: AlertConfiguration) -> Bool {
    return alertConfig.blocking || alertConfig.isNotRemembered()
  }

  /**
   Determine if an optional update dialog should be displayed, based on the configuration.

   - Parameter updateConfig: An `UpdateConfiguration`, parsed from the configuration file.

   - Returns: `true`, if an optional update should be displayed; `false`, if not.
   */
  func shouldShowOptionalUpdateDialog(updateConfig: UpdateConfiguration, appVersion: String) -> Bool {
    guard updateConfig.isNotRemembered() else { return false }

    return appVersion < updateConfig.version
  }

  /**
   Determine if a required update dialog should be displayed, based on the configuration.

   - Parameter updateConfig: An `UpdateConfiguration`, parsed from the configuration file.

   - Returns: `true`, if a required update dialog should be displayed; `false`, if not.
   */
  func shouldShowRequiredUpdateDialog(updateConfig: UpdateConfiguration, appVersion: String) -> Bool {
    return appVersion < updateConfig.version
  }

  func currentAppVersion() -> String? {
    return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
  }

}
