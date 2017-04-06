//
//  WatchSessionManager.swift
//  Photorama
//
//  Created by Andy Steinmann on 4/5/17.
//  Copyright © 2017 DLS. All rights reserved.
//

import WatchKit
import WatchConnectivity

class WatchSessionManager: NSObject, WCSessionDelegate {

    static let sharedManager = WatchSessionManager()
    fileprivate let session: WCSession? = WCSession.isSupported() ? WCSession.default() : nil
    fileprivate var validSession: WCSession? {
        // paired - the user has to have their device paired to the watch
        // watchAppInstalled - the user must have your watch app installed

        // Note: if the device is paired, but your watch app is not installed
        // consider prompting the user to install it for a better experience
        #if os(iOS)
            if let s = session, s.isPaired, s.isWatchAppInstalled {
                return s
            }
            return nil
        #else
            return session
        #endif
    }

    private override init() {
        super.init()
    }

    func startSession() {
        session?.delegate = self
        session?.activate()
    }

    /**
     * Called when the session has completed activation.
     * If session state is WCSessionActivationStateNotActivated there will be an error with more details.
     */
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {

    }

    #if os(iOS)
        /**
     * Called when the session can no longer be used to modify or add any new transfers and,
     * all interactive messages will be cancelled, but delegate callbacks for background transfers can still occur.
     * This will happen when the selected watch is being changed.
     */
        func sessionDidBecomeInactive(_ session: WCSession) {

        }
        /**
     * Called when all delegate callbacks for the previously selected watch has occurred.
     * The session can be re-activated for the now selected watch using activateSession.
     */
        func sessionDidDeactivate(_ session: WCSession) {

        }
    #endif
}

// MARK: Application Context
// use when your app needs only the latest information
// if the data was not sent, it will be replaced
extension WatchSessionManager {

    // Sender
    func updateApplicationContext(applicationContext: [String: AnyObject]) throws {
        if let session = validSession {
            do {
                try session.updateApplicationContext(applicationContext)
            } catch let error {
                throw error
            }
        }
    }

    // Receiver
    func session(session: WCSession, didReceiveApplicationContext applicationContext: [String: AnyObject]) {
        // handle receiving application context
        DispatchQueue.main.async() {
            // make sure to put on the main queue to update UI!
        }
    }
}

// MARK: User Info
// use when your app needs all the data
// FIFO queue
extension WatchSessionManager {

    // Sender
    func transferUserInfo(userInfo: [String: AnyObject]) -> WCSessionUserInfoTransfer? {
        print("sendingUserInf: \(userInfo)")
        return validSession?.transferUserInfo(userInfo)
    }

    func session(_ session: WCSession, didFinish userInfoTransfer: WCSessionUserInfoTransfer, error: Error?) {
        // implement this on the sender if you need to confirm that
        // the user info did in fact transfer
    }


    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
        // handle receiving user info
        DispatchQueue.main.async() {
            // make sure to put on the main queue to update UI!

            print("Received UserInfo: \(userInfo)")
        }
    }

}



extension Notification.Name {
    static let incomingFile = Notification.Name("incomingFile")
}

// MARK: Transfer File
extension WatchSessionManager {

    // Sender
    func transferFile(file: NSURL, metadata: [String: AnyObject]?) -> WCSessionFileTransfer? {
        return validSession?.transferFile(file as URL, metadata: metadata)
    }

    func session(_ session: WCSession, didFinish fileTransfer: WCSessionFileTransfer, error: Error?) {
        print("didFinishFileTransfer: \(fileTransfer)")
        if let error = error {
            print("didFinishFileTransfer ERROR!: \(error)")
        }
    }

    func session(_ session: WCSession, didReceive file: WCSessionFile) {
        print("Received File: \(file.fileURL) Meta: \(file.metadata!)")

        if let feedType = file.metadata?["feed"] as? String {
            //let documentsDirectories = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
            //let documentDirectory = documentsDirectories.first!

            //let docPath = "\(NSHomeDirectory())/Documents/"
            //let documentDirectory =  URL(string: docPath)!

            let folder = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.dls.photorama")!

            let path = folder.appendingPathComponent("feed_\(feedType).json")

            do {

                if FileManager.default.fileExists(atPath: path.absoluteString) {
                    let _ = try FileManager.default.replaceItemAt(path, withItemAt: file.fileURL, backupItemName: nil, options: [])
                } else {
                    let _ = try FileManager.default.copyItem(at: file.fileURL, to: path)
                }


            }

            catch {
                print("Error copying file: \(error)")
            }


            // handle receiving file
            DispatchQueue.main.async() {
                // make sure to put on the main queue to update UI!
                let payload = ["url": path, "feedType": feedType, "meta": file.metadata!] as Any
                NotificationCenter.default.post(name: .incomingFile, object: payload)
            }
        }


    }
}


// MARK: Interactive Messaging
extension WatchSessionManager {

    // Live messaging! App has to be reachable
    private var validReachableSession: WCSession? {
        if let session = validSession, session.isReachable {
            return session
        }
        return nil
    }

    // Sender
    func sendMessage(message: [String: AnyObject], replyHandler: (([String: Any]) -> Void)? = nil, errorHandler: ((Error) -> Void)? = nil) {
        validReachableSession?.sendMessage(message, replyHandler: replyHandler, errorHandler: errorHandler)
    }

    func sendMessageData(data: Data, replyHandler: ((Data) -> Void)? = nil, errorHandler: ((Error) -> Void)? = nil) {
        validReachableSession?.sendMessageData(data, replyHandler: replyHandler, errorHandler: errorHandler)
    }

    // Receiver
    func session(session: WCSession, didReceiveMessage message: [String: AnyObject], replyHandler: ([String: AnyObject]) -> Void) {
        // handle receiving message
        DispatchQueue.main.async() {
            // make sure to put on the main queue to update UI!
        }
    }

    func session(session: WCSession, didReceiveMessageData messageData: NSData, replyHandler: (NSData) -> Void) {
        // handle receiving message data
        DispatchQueue.main.async() {
            // make sure to put on the main queue to update UI!
        }
    }
}
