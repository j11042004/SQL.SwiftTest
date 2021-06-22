//
//  CodableModel.swift
//  FMDBTut
//
//  Created by APP技術部-周佳緯 on 2021/4/28.
//  Copyright © 2021 Appcoda. All rights reserved.
//

import Foundation
import UIKit
class MovieResultInfo: Codable {
    /**資料流水號*/
    var movieID:Int!
    /**片名*/
    var title:String
    /**類型*/
    var category:String
    /**上映年份*/
    var year:Int
    /**電影介紹url*/
    var movieURL:String
    /**電影海報url*/
    var coverURL:String
    /**是否看過*/
    var watched:Bool?
    /**是否喜歡*/
    var likes:Int?
    /**電影圖片*/
    var coverData:Data?
    /**電影圖片*/
    var coverImg : UIImage? {
        guard let data = coverData,
              let image = UIImage(data: data) else {
            return nil
        }
        
        return image
    }
}

extension MovieResultInfo {
    /**取得網路電影圖片*/
    public func getImageData() {
        if let _ = coverImg {
            return
        }
        
        guard let coverUrl = URL(string: coverURL) else {
            return
        }
        
        let requet = URLRequest(url: coverUrl, timeoutInterval: 3)
        let session = URLSession(configuration: .default)
        
        let dataTask = session.dataTask(with: requet) {
            [weak self] (data, response, error) in
            
            if let _ = error {
                return
            }
            
            guard let data = data else {
                return
            }
            
            self?.coverData = data
            
            // 不為 image 不儲存
            guard let _ = self?.coverImg else {
                return
            }
            
            if let info = self {
                MovieTableManager.instance.update(info: info, coverData: data)
                
                CoverTableManager.instance.insert(movieUrl: info.movieURL, imgURL: info.coverURL, imgData: info.coverData)
            }
        }
        
        dataTask.resume()
    }
}

struct MovieInfo {
    var movieID: Int!
    var title: String!
    var category: String!
    var year: Int!
    var movieURL: String!
    var coverURL: String!
    var watched: Bool!
    var likes: Int!
}

class CoverInfo: Codable {
    var `id` : Int!
    var coverURL : String
    var coverData : Data?
    var coverImg : UIImage? {
        guard let data = coverData,
              let image = UIImage(data: data) else {
            return nil
        }
        return image
    }
}
