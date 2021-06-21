//
//  CoverTableManager.swift
//  FMDBTut
//
//  Created by APP技術部-周佳緯 on 2021/6/16.
//  Copyright © 2021 Appcoda. All rights reserved.
//

import UIKit
import SQLite
class CoverTableManager: DatabaseManager {
    static let shared = CoverTableManager()
    
    private let tableName = "moviecover_Info"
    public private(set) lazy var coverTable = Table(tableName)
    public let `id` = Expression<Int64>("id")
    public let movieURL = Expression<String>("movieURL")
    public let coverURL = Expression<String>("coverURL")
    public let coverData = Expression<Data?>("coverData")
    
    override func createDatabase() -> Bool {
        let result = super.createDatabase()
        
        func createTable() {
            // temporary: 是否為臨時的 Table
            // ifNotExists: 是否不存在時才會建立
            // withoutRowid: 是否建立自動增長的 Id
            let createSql = coverTable.create(temporary: false, ifNotExists: true, withoutRowid: false) { (table) in
                table.column(id, primaryKey: .autoincrement)
                table.column(movieURL)
                table.column(coverURL)
                table.column(coverData, defaultValue: nil)
            }
            do {
                try databaseConnection?.run(createSql)
            } catch  {
                NSLog("create table error : \(error)")
            }
        }
        
        do {
            let isExists = try databaseConnection?.scalar(coverTable.exists)
            if isExists != true {
                createTable()
            }
        } catch  {
            NSLog("check table Error : \(error)")
            createTable()
        }
        return result
    }
}

extension CoverTableManager {
    func insert(movieUrl: String, imgURL: String, imgData: Data?) {
        do {
            if let _ = try select(movieUrl: movieUrl) {
                return
            }
            
            let converMovieURL : Expression<String> = Expression<String>(value: movieUrl)
            let coverImgUrl = Expression<String>(value: imgURL)
            let coverImgData = Expression<Data?>(value: imgData)
            
            let sql = coverTable.insert(movieURL <- converMovieURL,
                                        coverURL <- coverImgUrl,
                                        coverData <- coverImgData)
            try databaseConnection?.run(sql)
        } catch  {
            NSLog("insert error : \(error.localizedDescription)")
        }
    }
    
    public func select(movieUrl : String) throws -> CoverInfo? {
        let query = coverTable.filter(movieURL == movieUrl)
        do {
            let savedInfos = try databaseConnection?.prepare(query).map() { (row) -> CoverInfo in
                return try row.decode()
            }
            return savedInfos?.first
        } catch  {
            throw error
        }
    }
}