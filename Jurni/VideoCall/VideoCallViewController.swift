//
//  VideoCallViewController.swift
//  Jurni
//
//  Created by Devrath Rathee on 15/06/23.
//

import UIKit
import AgoraRtcKit
import AVFoundation
import FirebaseFunctions
import FirebaseAuth

class VideoCallViewController: UIViewController {
    
    var agoraEngine: AgoraRtcEngineKit!
    var userRole: AgoraClientRole = .broadcaster
    let appID = "9080b05c7b544be0b39fc84577ecb4c4"
    var token : String? = "007eJxTYDgodSYoJ122ZhY3t/VC+1eR9+7LTkpvN3kt+f9EeeQqtjIFhrSURFOjVANzUwOjJBMDQzNLExNLcwPTNEsLAwNTy8TEe/o7UhoCGRkmCd1iYIRCEF+EoTi9JCytsDTMJdA3OTwiLCyy3MeNgQEA/8IjrQ=="
    var channelName : String = "4JBDNkKrIq5QvFJQdf08"
    var fromNotification = false
    var agoraId : Int = 0
    var userId : String = ""
    var muteAudio = false
    var muteVideo = false
    
    @IBOutlet weak var localVideoView: UIView!
    @IBOutlet weak var remoteVideoView: UIView!
    @IBOutlet weak var localOverlayVideoView: UIView!
    
    @IBOutlet weak var remoteOverlayVideoView: UIView!
    @IBOutlet weak var micButton: UIButton!
    @IBOutlet weak var videoButton: UIButton!
    
    var joined: Bool = false
    let videoView = UIView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        agoraId = UserDefaults.standard.integer(forKey: Constants.AGORA_ID)
        print("Agora Id: \(agoraId)")
        userId = Auth.auth().currentUser!.uid
        fetchToken()
        initializeAgoraEngine()
        
    }
    
    func fetchToken(){
        lazy var functions = Functions.functions()
        print("Channel name : \(channelName) uid \(agoraId)")
        functions.httpsCallable("generateToken").call(["channel": channelName, "uid": "\(agoraId)", "role": true] as [String : Any]) { result, error in
          if let error = error as NSError? {
            if error.domain == FunctionsErrorDomain {
              let code = FunctionsErrorCode(rawValue: error.code)
              let message = error.localizedDescription
              print("Error : \(message) Code \(code)")
                
            }
          }
          if let data = result?.data as? [String: Any]
            {
              print("Rtc token : \(data["rtcToken"]!)")
              self.token = data["rtcToken"]! as? String
              if(!self.fromNotification){
                  self.startFirebaseCall()
              }
              DispatchQueue.main.async {
                  Task {
                      await self.joinChannel()
                      self.joined = true
                      //sender.isEnabled = true
                  }
              }
          }
        }
    }
    
    func joinChannel() async {
        if await !self.checkForPermissions() {
                showMessage(title: "Error", text: "Permissions were not granted")
                return
            }

            let option = AgoraRtcChannelMediaOptions()
            if self.userRole == .broadcaster {
                option.clientRoleType = .broadcaster
                setupLocalVideo()
            } else {
                option.clientRoleType = .audience
            }
            option.channelProfile = .communication
            print("Channel: \(channelName) Token \(token) Agora Id \(agoraId)")
            let result = agoraEngine.joinChannel(
                byToken: token, channelId: channelName, uid: UInt(agoraId), mediaOptions: option,
                joinSuccess: { (channel, uid, elapsed) in }
            )
                // Check if joining the channel was successful and set joined Bool accordingly
            if result == 0 {
                joined = true
            }
    }
    
    func leaveChannel() {
        agoraEngine.stopPreview()
            let result = agoraEngine.leaveChannel(nil)
            if result == 0 { joined = false }
    }
    
    func initializeAgoraEngine() {
        let config = AgoraRtcEngineConfig()
        config.appId = appID
        agoraEngine = AgoraRtcEngineKit.sharedEngine(with: config, delegate: self)
    }
    
    func setupLocalVideo() {
        agoraEngine.enableVideo()
        agoraEngine.startPreview()
        let videoCanvas = AgoraRtcVideoCanvas()
        videoCanvas.uid = 0
        videoCanvas.renderMode = .hidden
        videoCanvas.view = localVideoView
        agoraEngine.setupLocalVideo(videoCanvas)
    }
    
    @objc func buttonAction(sender: UIButton!) {
           if !joined {
               sender.isEnabled = false
               Task {
                   await joinChannel()
                   sender.isEnabled = true
               }
           } else {
               leaveChannel()
           }
       }

    func checkForPermissions() async -> Bool {
        var hasPermissions = await self.avAuthorization(mediaType: .video)
        if !hasPermissions { return false }
        hasPermissions = await self.avAuthorization(mediaType: .audio)
        return hasPermissions
    }

    func avAuthorization(mediaType: AVMediaType) async -> Bool {
        let mediaAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: mediaType)
        switch mediaAuthorizationStatus {
        case .denied, .restricted: return false
        case .authorized: return true
        case .notDetermined:
            return await withCheckedContinuation { continuation in
                AVCaptureDevice.requestAccess(for: mediaType) { granted in
                    continuation.resume(returning: granted)
                }
            }
        @unknown default: return false
        }
    }
    
    func showMessage(title: String, text: String, delay: Int = 2) -> Void {
        let deadlineTime = DispatchTime.now() + .seconds(delay)
        DispatchQueue.main.asyncAfter(deadline: deadlineTime, execute: {
            let alert = UIAlertController(title: title, message: text, preferredStyle: .alert)
            self.present(alert, animated: true)
            alert.dismiss(animated: true, completion: nil)
        })
    }
    
    override func viewDidDisappear(_ animated: Bool) {
           super.viewDidDisappear(animated)
           leaveChannel()
           DispatchQueue.global(qos: .userInitiated).async {AgoraRtcEngineKit.destroy()}
       }
    
    @IBAction func backAction(_ sender: Any) {
        leaveChannel()
        self.dismiss(animated: false)
    }
        
    @IBAction func hangUpAction(_ sender: Any) {
        leaveChannel()
        self.dismiss(animated: false)
    }
    
    @IBAction func videoOffAction(_ sender: Any) {
        if (muteVideo){
            muteVideo = false
            videoButton.setImage(UIImage(named: "video"), for: .normal)
            localOverlayVideoView.isHidden = true
        }else{
            muteVideo = true
            videoButton.setImage(UIImage(named: "videoff"), for: .normal)
            localOverlayVideoView.isHidden = false
        }
        agoraEngine.enableLocalVideo(!muteVideo)
    }
    
    @IBAction func audioOffAction(_ sender: Any) {
        if (muteAudio){
            muteAudio = false
            micButton.setImage(UIImage(named: "micwhite"), for: .normal)
        }else{
            muteAudio = true
            micButton.setImage(UIImage(named: "micoff"), for: .normal)
        }
        agoraEngine.muteLocalAudioStream(muteAudio)
    }
    
    func startFirebaseCall(){
        lazy var functions = Functions.functions()
        functions.httpsCallable("startChatCall").call(["threadId": channelName, "meetingLink": "https://app.jurni.io/meet/\(channelName)"] as [String : Any]) { result, error in
          if let error = error as NSError? {
            if error.domain == FunctionsErrorDomain {
              let code = FunctionsErrorCode(rawValue: error.code)
              let message = error.localizedDescription
              print("Error : \(message) Code \(code)")
                
            }
          }
          if let data = result?.data as? [String: Any]
            {
              print("Data: \(data)")
            }
        }
    }
}

extension VideoCallViewController: AgoraRtcEngineDelegate {
    // Callback called when a new host joins the channel
    func rtcEngine(_ engine: AgoraRtcEngineKit, didJoinedOfUid uid: UInt, elapsed: Int) {
            let videoCanvas = AgoraRtcVideoCanvas()
            videoCanvas.uid = uid
            videoCanvas.renderMode = .hidden
            videoCanvas.view = remoteVideoView
            self.agoraEngine.setupRemoteVideo(videoCanvas)
    }
    
     func rtcEngine(_ engine: AgoraRtcEngineKit, didOfflineOfUid uid: UInt, reason: AgoraUserOfflineReason) {
             let videoCanvas = AgoraRtcVideoCanvas()
             videoCanvas.uid = uid
             videoCanvas.renderMode = .hidden
             videoCanvas.view = UIView()
             self.agoraEngine.setupRemoteVideo(videoCanvas)
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, didLocalVideoEnabled enabled: Bool, byUid uid: UInt) {
        if(enabled){
            remoteOverlayVideoView.isHidden = true
        }else{
            remoteOverlayVideoView.isHidden = false
        }
    }
}


