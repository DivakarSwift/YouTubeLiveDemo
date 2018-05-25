//
//  YouTubeHelper.swift
//  DemoSwift
//
//  Created by Sohil on 22/05/18.
//  Copyright © 2018 gao. All rights reserved.
//

import UIKit

struct YouTubeHelper {
    
    private static let API_KEY = "AIzaSyDeuqvWHZci_py38WrumBXEF26Pha3-utY"
    
    //https://www.googleapis.com/youtube/v3/videos?part=snippet%2CliveStreamingDetails&id=pQzaHPoNX1I&fields=items%2FliveStreamingDetails%2FactiveLiveChatId&key=AIzaSyDeuqvWHZci_py38WrumBXEF26Pha3-utY
    
    static func getLiveChatID(forVideoId id: String, completion: @escaping (String?, Error?) -> ()) {
        let url = "https://www.googleapis.com/youtube/v3/videos?part=snippet%2CliveStreamingDetails&id=\(id)&fields=items%2FliveStreamingDetails%2FactiveLiveChatId&key=\(API_KEY)"
        callWebservice(withURL: URL(string: url)!) { (response, error) in
            if let response = response, let arrItems = response["items"] as? Array<Dictionary<String, Any>>, arrItems.count > 0 {
                if let liveStreamingDetails = arrItems[0]["liveStreamingDetails"] as? Dictionary<String, Any>, let liveChatId = liveStreamingDetails["activeLiveChatId"] as? String {
                    print(liveChatId)
                    completion(liveChatId, nil)
                } else {
                    completion(nil, nil)
                }
            } else if let error = error {
                completion(nil, error)
            }
        }
    }
    
    static func getComments(forLiveChatId id: String, completion: @escaping (YTLiveCommentsData?, Error?) -> ()) {
        let url = "https://www.googleapis.com/youtube/v3/liveChat/messages?liveChatId=\(id)&part=snippet&fields=items(authorDetails(channelId%2CdisplayName%2CisChatModerator%2CisChatOwner%2CisChatSponsor%2CprofileImageUrl)%2Csnippet(displayMessage%2CpublishedAt%2CsuperChatDetails))%2CnextPageToken%2CpollingIntervalMillis&key=\(API_KEY)"
        callWebservice(withURL: URL(string: url)!) { (response, error) in
            if let response = response {
                completion(YTLiveCommentsData(response), nil)
            } else if let error = error {
                completion(nil, error)
            }
        }
    }
    
    static func getComments(forLiveChatId id: String, token: String, completion: @escaping (YTLiveCommentsData?, Error?) -> ()) {
        let url = "https://www.googleapis.com/youtube/v3/liveChat/messages?liveChatId=\(id)&part=snippet&pageToken=\(token)&fields=items(authorDetails%2Csnippet(displayMessage%2CpublishedAt%2CsuperChatDetails))%2CnextPageToken%2CpollingIntervalMillis&key=\(API_KEY)"
        callWebservice(withURL: URL(string: url)!) { (response, error) in
            if let response = response {
                completion(YTLiveCommentsData(response), nil)
            } else if let error = error {
                completion(nil, error)
            }
        }
    }
    
    static func callWebservice(withURL url: URL, completion: @escaping (Dictionary<String, Any>?, Error?) -> ()) {
        URLSession.shared.dataTask(with: url) { (response, _, error) in
            DispatchQueue.main.async {
                if let error = error {
                    print(error.localizedDescription)
                    completion(nil, error)
                } else if let response = response {
                    do {
                        if let jsonData = try JSONSerialization.jsonObject(with: response, options: JSONSerialization.ReadingOptions.allowFragments) as? Dictionary<String, Any> {
                            completion(jsonData, nil)
                        }
                    } catch {
                        print(error.localizedDescription)
                        completion(nil, error)
                    }
                }
            }
        }.resume()
    }
}

struct YTLiveCommentsData {
    
    var nextPageToken: String!
    var pollingIntervalMillis: Int!
    var arrComments = [YTComments]()
    
    init() {
        
    }
    
    init(_ dictCommentsData: Dictionary<String, Any>) {
        nextPageToken = dictCommentsData["nextPageToken"] as? String ?? ""
        pollingIntervalMillis = dictCommentsData["pollingIntervalMillis"] as? Int ?? 0
        if let items = dictCommentsData["items"] as? Array<Dictionary<String, Any>>, items.count > 0 {
            for item in items {
                if let commentData = item["snippet"] as? Dictionary<String, Any> {
                    arrComments.append(YTComments(publishedTime: commentData["publishedAt"] as! String, comment: commentData["displayMessage"] as! String))
                }
            }
        }
    }
}

struct YTComments {
    var publishedTime: String, comment: String
}
