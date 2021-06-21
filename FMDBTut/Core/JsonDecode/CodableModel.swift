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
    var movieID : Int!
    var title : String
    var category : String
    var year : Int
    var movieURL : String
    var coverURL : String
    var watched : Bool?
    var likes : Int?
    var coverData : Data?
    var coverImg : UIImage? {
        guard let data = coverData,
              let image = UIImage(data: data) else {
            return nil
        }
        return image
    }
}

extension MovieResultInfo {
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
                MovieTableManager.shared.update(info: info, coverData: data)
                
                CoverTableManager.shared.insert(movieUrl: info.movieURL, imgURL: info.coverURL, imgData: info.coverData)
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
