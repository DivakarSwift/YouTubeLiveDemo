//
//  YouTubeHelper.swift
//  DemoSwift
//
//  Created by Sohil on 22/05/18.
//  Copyright © 2018 gao. All rights reserved.
//

import UIKit

struct YouTubeHelper {
    
    private static let API_KEY = "AIzaSyASWj3M5Abkl_6sHx06ZqOnuz2I1GuL0QA"
    
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
            print(response)
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
    
    static func postComment(forLiveChatId id: String, authToken: String, comment: String, completion: @escaping (Bool, String) -> ()) {
        let url = "https://www.googleapis.com/youtube/v3/liveChat/messages?part=snippet&key=\(API_KEY)"
        let paramMsg = ["messageText" : comment]
        let paramTextMsg = ["type" : "textMessageEvent", "liveChatId" : id, "textMessageDetails" : paramMsg] as [String : Any]
        let paramSnippet = ["snippet" : paramTextMsg]
        debugPrint(paramSnippet)
        postAPIWithFormData(url, paramSnippet, ["Authorization" : "Bearer " + authToken]) { (response, error) in
            if let response = response {
                if let responseError = response["error"] as? Dictionary<String, Any>, let code = responseError["code"] as? Int, code > 0  {
                    if let message = responseError["message"] as? String {
                        completion(false, message)
                    } else {
                        completion(false, "Something went wrong. Please try again later!")
                    }
                } else {
                    completion(true, "Your Comment will appear soon.")
                }
            }
            debugPrint(response ?? "No response")
            debugPrint(error?.localizedDescription ?? "No Error")
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
    
    //MARK: Post API With Formdata
    
    static func postAPIWithFormData(_ apiURL: String, _ paramaters: [String : Any], _ headers: [String : String]? = nil, _ completion : @escaping (_ dictResponse: Dictionary<String, AnyObject>?, _ error: Error?) -> ()){
        let url = URL(string: apiURL)
        var request = URLRequest(url: url!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField:"Content-Type");
        if let headers = headers{
            for value in headers.enumerated(){
                request.setValue(value.element.value, forHTTPHeaderField: value.element.key)
            }
        }
        request.cachePolicy = URLRequest.CachePolicy.reloadIgnoringLocalCacheData
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: paramaters, options: .prettyPrinted)
            let task = URLSession.shared.dataTask(with: request, completionHandler: { (data, response, error) in
                DispatchQueue.main.async {
                    do{
                        if let data = data{
                            let json = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? Dictionary<String, AnyObject>
                            if let parsedJSON = json {
                                //Parsed JSON
                                completion(parsedJSON, nil)
                            }else{
                                // Woa, okay the json object was nil, something went worng. Maybe the server isn't running?
                                let jsonStr = String(data: data, encoding: .utf8)
                                #if DEBUG
                                print("Error could not parse JSON: \(jsonStr ?? "")")
                                #endif
                            }
                        }else{
                            completion(nil, error)
                        }
                    }catch let error{
                        completion(nil, error)
                    }
                }
            })
            task.resume()
        } catch {
            debugPrint("Error while Converting paramaters \(error.localizedDescription)")
        }
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
