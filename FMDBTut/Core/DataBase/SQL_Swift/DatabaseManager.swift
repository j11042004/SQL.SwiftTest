//
//  DatabaseManager.swift
//  FMDBTut
//
//  Created by APP技術部-周佳緯 on 2021/6/16.
//  Copyright © 2021 Appcoda. All rights reserved.
//

import UIKit
import SQLite

class DatabaseManager: NSObject {
    static let instance = DatabaseManager()
    
    private let databaseFileName:String = "SwiftSQLDatabase.sqlite"
    
    public private(set) var dataBasePath:String = ""//.sqlite檔案路徑
    public private(set) var databaseConnection:Connection?
    public private(set) var created:Bool = false//資料庫是否已建立
    
    /**資料庫版本*/
    public var dbversion : Int {
        guard let version = databaseConnection?.userVersion else {
            return 0
        }
        
        return Int(version)
    }
    
    override init() {
        super.init()
        
        let documentsDirectory:String = (NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString) as String
        dataBasePath = NSString.path(withComponents: [documentsDirectory, databaseFileName]) as String
        
        createDatabase()
        NSLog("data base Path : \(dataBasePath)")
    }
    
    /**創建資料庫*/
    public func createDatabase() {
        let fileExists:Bool = FileManager.default.fileExists(atPath: dataBasePath)
        
        do {
            databaseConnection = try Connection(dataBasePath)//連接資料庫
        } catch  {
            NSLog("create error : \(error.localizedDescription)")
        }
        
        /*DB檔案不存在*/
        if !fileExists,databaseConnection != nil {
            created = true
        }
        
        /*Thread 安全設置，以下兩種方式選一種即可*/
        databaseConnection?.busyTimeout = 5.0
        databaseConnection?.busyHandler(){
            tries -> Bool in
            
            return tries < 5
        }
        
        /*開啟 Debug 模式 可以 Show 執行的 SQL*/
        databaseConnection?.trace(){
            result in
            
            NSLog("run SQL : \(result)")
        }
    }
    
    /**大量資料新增，失敗可rollback*/
    public func transaction(_ block: () -> Void) throws {
        do {
            try databaseConnection?.transaction(block: block)
        } catch {
            throw error
        }
    }
}
