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
    private let databaseFileName = "SwiftSQLDatabase.sqlite"
    public private(set) var dataBasePath : String = ""
    public private(set) var databaseConnection : Connection?
    
    public var dbversion : Int {
        guard let version = databaseConnection?.userVersion else {
            return 0
        }
        return Int(version)
    }
    
    override init() {
        super.init()
        
        let documentsDirectory = (NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString) as String
        dataBasePath = NSString.path(withComponents: [documentsDirectory, databaseFileName]) as String
        NSLog("data base Path : \(dataBasePath)")
    }
    
    
    
    public func createDatabase() -> Bool {
        var created = false
        if !FileManager.default.fileExists(atPath: dataBasePath) {
            do {
                
                databaseConnection = try Connection(dataBasePath)
                
                created = true
            } catch  {
                NSLog("create error : \(error.localizedDescription)")
            }
        }
        else {
            databaseConnection = try? Connection(dataBasePath)
        }
        /// Thread 安全設置，以下兩種方式選一種即可
        databaseConnection?.busyTimeout = 5.0
        databaseConnection?.busyHandler(){ (tries) -> Bool in
            return tries < 5
        }
        
        // 開啟 Debug 模式 可以 Show 執行的 SQL
        databaseConnection?.trace(){ (result) in
            NSLog("run SQL : \(result)")
        }
        return created
    }
    
    public func transaction(_ block: () -> Void) throws {
        do {
            try databaseConnection?.transaction(block: block)
        } catch {
            throw error
        }
    }
}
