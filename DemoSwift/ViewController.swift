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

class ViewController: UIViewController, UITableViewDataSource, UITextFieldDelegate, YTPlayerViewDelegate {

    @IBOutlet var txtComment: UITextField!
    @IBOutlet var viewPlayer: YTPlayerView!
    @IBOutlet var tableView: UITableView!
    @IBOutlet var viewGradient: UIView!
    
    var maskLayer = CAGradientLayer()
    
    var dataArray : NSMutableArray = []
    let VIDEO_ID = "kDI8dD4vReE"
    var ytCommentsData = YTLiveCommentsData()
    
    override func viewDidLoad() {
        super.viewDidLoad()
     
        txtComment.delegate = self
        dataArray = NSMutableArray.init()
        self.loadDemoVideo()
        self.addLayer()
        getCommentsData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
    @IBAction func onSend(_ sender: Any) {
        if (!(txtComment.text != nil) || txtComment.text?.count == 0){
            return
        }
        dataArray.add(txtComment.text as? String)
        tableView.reloadData()
        
        txtComment.text = ""
        
        let indexPath = IndexPath(row: dataArray.count-1, section: 0)

        tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
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
                YouTubeHelper.getComments(forLiveChatId: liveChatID, completion: { (commentData, error) in
                    if let commentData = commentData {
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
    
    func scrollToBottom(){
//        DispatchQueue.main.async {
            let indexPath = IndexPath(row: self.ytCommentsData.arrComments.count-1, section: 0)
            self.tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
//        }
    }
}

