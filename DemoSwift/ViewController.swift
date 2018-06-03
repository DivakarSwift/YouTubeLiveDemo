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

class ViewController: UIViewController, UITableViewDataSource, UITextFieldDelegate, YTPlayerViewDelegate, GIDSignInUIDelegate, UITableViewDelegate {

    @IBOutlet weak var viewLive: UIView! {
        didSet {
            viewLive.clipsToBounds = true
            viewLive.layer.cornerRadius = 2
        }
    }
    @IBOutlet weak var btnStar: UIButton!
    @IBOutlet var txtComment: UITextField!
    @IBOutlet var viewPlayer: YTPlayerView!
    @IBOutlet var tableView: UITableView!
    @IBOutlet var viewGradient: UIView!
    
    var maskLayer = CAGradientLayer()
    
    var dataArray : NSMutableArray = []
    let VIDEO_ID = "xS6pwQ1Gs2s"
    var ytCommentsData = YTLiveCommentsData()
    var liveChatId: String?
    var keyboardHeight: CGFloat = 0.0
    private struct HeartAttributes {
        static let heartSize: CGFloat = 30
        static let burstDelay: TimeInterval = 0.1
    }
    var burstTimer: Timer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        hideKeyboardWhenTappedAround() //dismiss keyboard
        GIDSignIn.sharedInstance().scopes = ["https://www.googleapis.com/auth/youtube.readonly", "https://www.googleapis.com/auth/youtube", "https://www.googleapis.com/auth/youtube.force-ssl"]
        GIDSignIn.sharedInstance().delegate = self
        GIDSignIn.sharedInstance().uiDelegate = self
        GIDSignIn.sharedInstance().signInSilently()
        txtComment.delegate = self
        dataArray = NSMutableArray.init()
        self.loadDemoVideo()
        self.addLayer()
        getCommentsData()
        
        //To add Star
        let longPressGestureStar = UILongPressGestureRecognizer(target: self, action: #selector(didLongPressStar(longPressGesture:)))
        longPressGestureStar.minimumPressDuration = 0.2
        btnStar.addGestureRecognizer(longPressGestureStar)
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow),
            name: NSNotification.Name.UIKeyboardWillShow,
            object: nil
        )
    }

    @objc func keyboardWillShow(_ notification: Notification) {
        if let keyboardFrame: NSValue = notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue {
            let keyboardRectangle = keyboardFrame.cgRectValue
            keyboardHeight = keyboardRectangle.height
//            textFieldDidBeginEditing(txtComment)
            animateViewMoving(up: true, moveValue: keyboardHeight)
        }
    }

    @objc func didLongPressStar(longPressGesture: UILongPressGestureRecognizer) {
        switch longPressGesture.state {
        case .began:
            burstTimer = Timer.scheduledTimer(timeInterval: HeartAttributes.burstDelay, target: self, selector: #selector(showTheStar(gesture:)), userInfo: nil, repeats: true)
        case .ended, .cancelled:
            burstTimer?.invalidate()
        default:
            break
        }
    }
    
    @IBAction func btnStarTapped(_ sender: UIButton) {
        showTheStar(gesture: nil)
    }
    
    @objc func showTheStar(gesture: UITapGestureRecognizer?) {
        let star = HeartView(frame: CGRect(x: UIScreen.main.bounds.width, y: 0, width: HeartAttributes.heartSize, height: HeartAttributes.heartSize), imgSimpleName: "star", imgBorderName: "star")
        view.addSubview(star)
        let fountainX = ((btnStar.frame.origin.x + (btnStar.frame.size.width / 2))) //HeartAttributes.heartSize / 2.0 + 20
        let fountainY = view.bounds.height - HeartAttributes.heartSize / 2.0 - 4
        star.center = CGPoint(x: fountainX, y: fountainY)
        star.animateInView(view: view)
    }
    
    @IBAction func btnCloseTapped(_ sender: UIButton) {
        
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
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
//        animateViewMoving(up: true, moveValue: keyboardHeight)
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        animateViewMoving(up: false, moveValue: keyboardHeight)
    }
    
    func animateViewMoving (up:Bool, moveValue :CGFloat){
        let movementDuration:TimeInterval = 0.3
        let movement:CGFloat = ( up ? -moveValue : moveValue)
        UIView.beginAnimations( "animateView", context: nil)
        UIView.setAnimationBeginsFromCurrentState(true)
        UIView.setAnimationDuration(movementDuration )
        self.view.frame = self.view.frame.offsetBy(dx: 0, dy: movement)
        UIView.commitAnimations()
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
        if state == .playing {
            //Once Video is start playing show the stars
            Timer.scheduledTimer(timeInterval: 0.9, target: self, selector: #selector(showTheStar), userInfo: nil, repeats: true)
        }
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
        let cell = tableView.dequeueReusableCell(withIdentifier: "cellComment") as! CommentsCell
        cell.lblComment.text = ytCommentsData.arrComments[indexPath.row].comment
        return cell
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
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

// Put this piece of code anywhere you like
extension UIViewController {
    func hideKeyboardWhenTappedAround() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
}
