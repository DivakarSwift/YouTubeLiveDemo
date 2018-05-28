//
//  ViewController.swift
//  DemoSwift
//
//  Created by gao on 5/18/18.
//  Copyright © 2018 gao. All rights reserved.
//

import UIKit
import youtube_ios_player_helper
import GoogleAPIClientForREST
import GoogleSignIn

let appDel = UIApplication.shared.delegate!

class ViewController: UIViewController, UITableViewDataSource, UITextFieldDelegate, YTPlayerViewDelegate, GIDSignInUIDelegate {

    @IBOutlet weak var btnLove: UIButton!
    @IBOutlet var txtComment: UITextField!
    @IBOutlet var viewPlayer: YTPlayerView!
    @IBOutlet var tableView: UITableView!
    @IBOutlet var viewGradient: UIView!
    
    var maskLayer = CAGradientLayer()
    
    var dataArray : NSMutableArray = []
    let VIDEO_ID = "xS6pwQ1Gs2s"
    var ytCommentsData = YTLiveCommentsData()
    var liveChatId: String?
    
    private struct HeartAttributes {
        static let heartSize: CGFloat = 36
        static let burstDelay: TimeInterval = 0.1
    }
    var burstTimer: Timer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        GIDSignIn.sharedInstance().scopes = ["https://www.googleapis.com/auth/youtube.readonly", "https://www.googleapis.com/auth/youtube", "https://www.googleapis.com/auth/youtube.force-ssl"]
        GIDSignIn.sharedInstance().delegate = self
        GIDSignIn.sharedInstance().uiDelegate = self
        GIDSignIn.sharedInstance().signInSilently()
        txtComment.delegate = self
        dataArray = NSMutableArray.init()
        self.loadDemoVideo()
        self.addLayer()
        getCommentsData()
        
        //To add Love
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(didLongPress))
        longPressGesture.minimumPressDuration = 0.2
        btnLove.addGestureRecognizer(longPressGesture)
    }

    @objc func didLongPress(longPressGesture: UILongPressGestureRecognizer) {
        switch longPressGesture.state {
        case .began:
            burstTimer = Timer.scheduledTimer(timeInterval: HeartAttributes.burstDelay, target: self, selector: #selector(showTheLove), userInfo: nil, repeats: true)
        case .ended, .cancelled:
            burstTimer?.invalidate()
        default:
            break
        }
    }

    @IBAction func btnLoveTapped(_ sender: UIButton) {
        showTheLove(gesture: nil)
    }
    
    @objc func showTheLove(gesture: UITapGestureRecognizer?) {
        let heart = HeartView(frame: CGRect(x: UIScreen.main.bounds.width, y: 0, width: HeartAttributes.heartSize, height: HeartAttributes.heartSize))
        view.addSubview(heart)
        let fountainX = ((btnLove.frame.origin.x + (btnLove.frame.size.width / 2)) - ((HeartAttributes.heartSize / 2.0))) //HeartAttributes.heartSize / 2.0 + 20
        let fountainY = view.bounds.height - HeartAttributes.heartSize / 2.0 - 10
        heart.center = CGPoint(x: fountainX, y: fountainY)
        print(fountainX)
        print(fountainY)
        print(heart)
        heart.animateInView(view: view)
    }
    
    @IBAction func onSend(_ sender: Any) {
        if !GIDSignIn.sharedInstance().hasAuthInKeychain() || GIDSignIn.sharedInstance().currentUser == nil {
            GIDSignIn.sharedInstance().signIn()
        } else {
            guard liveChatId != nil else {
                return
            }
            print(GIDSignIn.sharedInstance().currentUser.authentication.accessToken)
            if GIDSignIn.sharedInstance().currentUser.authentication.accessTokenExpirationDate.days(from: Date()) > 0 {
                postComment()
            } else {
                GIDSignIn.sharedInstance().currentUser.authentication.refreshTokens { (authentication, error) in
                    if let error = error {
                        self.showAlert(error.localizedDescription)
                    } else {
                        self.postComment()
                    }
                }
            }
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return true
    }
    
    private func loadDemoVideo() {
        let playerVars = ["playsinline": 1, "autoplay": 1, "autohide": 1, "controls" : 0, "showinfo" : 0, "modestbranding" : 1, "rel" : 0, "origin" : "https://www.youtube.com"] as [String : Any]
        viewPlayer.load(withVideoId: VIDEO_ID, playerVars: playerVars)
        viewPlayer.delegate = self
    }
    
    func playerViewDidBecomeReady(_ playerView: YTPlayerView) {
        playerView.playVideo()
    }
    
    func playerView(_ playerView: YTPlayerView, didChangeTo state: YTPlayerState) {
//        if state == .playing {
//            let uilabel = UILabel(frame: CGRect(x: 0, y: 0, width: 150, height: 100))
//            uilabel.backgroundColor = .red
//            UIApplication.shared.delegate!.window!?.rootViewController!.view.addSubview(uilabel)
//        }
    }
    
    func playerView(_ playerView: YTPlayerView, receivedError error: YTPlayerError) {
        print("Error while loading ", error)
    }
    
    private func addLayer() {
        maskLayer = CAGradientLayer()
        maskLayer.frame = viewGradient.bounds
        maskLayer.colors = [UIColor.clear.cgColor, UIColor.clear.cgColor, UIColor.clear.cgColor, UIColor.black.cgColor]
        maskLayer.locations = [0.4, 1, 1, 0.1]
        viewGradient.layer.addSublayer(maskLayer)
    }
    
    // tableview datasource / delegate
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return ytCommentsData.arrComments.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cellComment")
        let lblComment = cell?.viewWithTag(1) as! UILabel
        lblComment.text = ytCommentsData.arrComments[indexPath.row].comment
        return cell!
    }
    
    func getCommentsData() {
        YouTubeHelper.getLiveChatID(forVideoId: VIDEO_ID) { (liveChatID, error) in
            if let liveChatID = liveChatID {
                self.liveChatId = liveChatID
                YouTubeHelper.getComments(forLiveChatId: liveChatID, completion: { (commentData, error) in
                    if let commentData = commentData, commentData.arrComments.count > 0 {
                        self.ytCommentsData = commentData
                        print(self.ytCommentsData.nextPageToken)
                        print(self.ytCommentsData.pollingIntervalMillis)
                        self.tableView.reloadData()
                        self.scrollToBottom()
                        let time = Double(self.ytCommentsData.pollingIntervalMillis) * 0.001
                        print("Calling another api in \(time) seconds")
                        Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { (timer) in
                            YouTubeHelper.getComments(forLiveChatId: liveChatID, token: self.ytCommentsData.nextPageToken, completion: { (newCommentData, error) in
                                if let newCommentData = newCommentData, newCommentData.arrComments.count > 0 {
                                    self.ytCommentsData.nextPageToken = newCommentData.nextPageToken
                                    self.ytCommentsData.pollingIntervalMillis = newCommentData.pollingIntervalMillis
                                    var indexPaths = [IndexPath]()
                                    let currentCount = self.ytCommentsData.arrComments.count
                                    for index in 0..<newCommentData.arrComments.count {
                                        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(index) + 0.1, execute: {
                                            indexPaths.append(IndexPath(row: currentCount + index, section: 0))
                                            self.ytCommentsData.arrComments.append(newCommentData.arrComments[index])
                                            self.tableView.beginUpdates()
                                            self.tableView.insertRows(at: [IndexPath(row: currentCount + index, section: 0)], with: UITableViewRowAnimation.bottom)
                                            self.tableView.endUpdates()
                                            self.scrollToBottom()
                                        })
                                    }
                                }
                            })
                        })
                    } else if let error = error {
                        print(error.localizedDescription)
                    }
                })
            }
        }
    }
    
    func postComment() {
        if txtComment.text!.count > 0 {
            YouTubeHelper.postComment(forLiveChatId: liveChatId!, authToken: GIDSignIn.sharedInstance().currentUser.authentication.accessToken, comment: txtComment.text!) { (isPosted, msg) in
                self.txtComment.text = ""
                self.showAlert(msg)
            }
        } else {
            showAlert("Comment cannot be empty.")
        }
    }
    
    func scrollToBottom(){
//        DispatchQueue.main.async {
            let indexPath = IndexPath(row: self.ytCommentsData.arrComments.count-1, section: 0)
            self.tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
//        }
    }
    
    private func showAlert(_ message: String) {
        let alertController: UIAlertController = UIAlertController.init(title: "", message: message, preferredStyle: UIAlertControllerStyle.alert)
        
        let okAction: UIAlertAction = UIAlertAction.init(title: "OK", style: UIAlertActionStyle.default,
                                                         handler: { (action) -> Void in
        })
        
        alertController.addAction(okAction)
        self.present(alertController, animated: true, completion: nil)
    }
}

extension ViewController: GIDSignInDelegate {
    //Google Sign In
    
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!,
              withError error: Error!) {
        if let error = error {
            print("\(error.localizedDescription)")
            showAlert(error.localizedDescription)
        }
    }
    
    func sign(_ signIn: GIDSignIn!, didDisconnectWith user: GIDGoogleUser!,
              withError error: Error!) {
        // Perform any operations when the user disconnects from app here.
        // ...
        showAlert(error.localizedDescription)
    }
}

extension Date {
    /// Returns the amount of days from another date
    func days(from date: Date) -> Int {
        return Calendar.current.dateComponents([.day], from: date, to: self).day ?? 0
    }
}
