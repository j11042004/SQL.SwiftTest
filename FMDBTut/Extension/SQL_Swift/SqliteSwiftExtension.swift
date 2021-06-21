//
//  SqliteSwiftExtension.swift
//  FMDBTut
//
//  Created by APP技術部-周佳緯 on 2021/5/14.
//  Copyright © 2021 Appcoda. All rights reserved.
//

import Foundation
import SQLite

extension Connection {
    /// 取得/設定 DataBase 的 UserVersion
    public var userVersion : Int64 {
        get {
            return try! scalar("PRAGMA user_version") as! Int64
        }
        set {
            try! run("PRAGMA user_version = \(newValue)")
        }
    }
}
