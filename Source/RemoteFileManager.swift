//
//  RemoteFileManager.swift
//  Pods
//
//  Created by Dan Trenz on 1/20/16.
//
//

import Foundation

class RemoteFileManager {

  let remoteFileURL: NSURL

  init(remoteFileURL: NSURL) {
    self.remoteFileURL = remoteFileURL
  }

    func fetchRemoteFile(callback: @escaping (NSData) -> Void) {
    performRemoteFileRequest(session: URLSession.shared, url: remoteFileURL, responseHandler: callback)
  }

    func performRemoteFileRequest(session: URLSession, url: NSURL, responseHandler: @escaping (_ data: NSData) -> Void) {
        let task = session.dataTask(with: url as URL) { (data, _, error) -> Void in
      if let error = error {
        print("LaunchGate — Error: \(error.localizedDescription)")
      }

      guard let data = data else {
        print("LaunchGate — Error: Remote configuration file response was empty.")
        return
      }

            responseHandler(data as NSData)
    }

    task.resume()
  }

}
