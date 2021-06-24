//
//  SQLiteUpgrade.swift
//  FMDBTut
//
//  Created by APP系統開發二部-劉國昱 on 2021/6/22.
//  Copyright © 2021 Mitake. All rights reserved.
//

import Foundation
import SQLite

class SQLiteUpgrade: NSObject {
    static let instance = SQLiteUpgrade()
    
    /*要使用的全部Table*/
    public var tableInfo: Dictionary<String,String> = Dictionary()//key:table名稱 value: create sqlCmd
    
    private let version: Int64 = 1//資料庫版本號
    
    /**資料表更新*/
    func onUpgrade(){
        /*版本號相同，不更新*/
        if(version == DatabaseManager.instance.dbversion){
            return
        }
        
        deleteNoUseTable()//若原table在更版後不再被使用，則刪除掉
        upgradeTable()//逐筆table重建，搬移資料到新table
        
        /*更新完成，目前版本變更為新的版本號*/
        DatabaseManager.instance.databaseConnection?.userVersion = version
    }
    
    /**若原table在更版後不再被使用，則刪除掉*/
    private func deleteNoUseTable(){
        let cmd: String = "SELECT name FROM sqlite_master WHERE type='table' AND name NOT IN ('sqlite_sequence') ORDER BY name";
        var results: Statement?
        
        do{
            results = try DatabaseManager.instance.databaseConnection?.prepare(cmd)
        }catch{
            print(error.localizedDescription)
        }
        
        /*用差集取得被廢棄的table*/
        if results != nil{
            var oldTableNames:Set<String> = Set()//原db全部的table名稱
            
            /*取出目前全部table名稱*/
            for row in results! {
                if row[0] != nil{
                    oldTableNames.insert(row[0] as! String)
                }
            }
            
            let newTableNames:Set<String> = Set(tableInfo.keys)//更版後的全部table名稱
            var scrapTables:Set<String> = Set(oldTableNames)//原db更版後，被廢棄的table
            
            /*原tables - 更版後tables，剩下來的就是要被廢棄的table*/
            scrapTables = oldTableNames.subtracting(newTableNames)//取差集
            
            /*刪除table*/
            for tableName in scrapTables{
                let table: Table = Table(tableName)
                
                do {
                    _ = try DatabaseManager.instance.databaseConnection?.run(table.drop())
                } catch  {
                    print(String(format: "delete error:%@",error.localizedDescription))
                }
            }
        }
    }
    
    /**創建新table，把舊table的資料搬移後刪除*/
    private func upgradeTable(){
        let table: Table = Table("sqlite_master")
        let name: Expression<String> = Expression<String>("name")
        
        /*逐筆取出全部新table名稱*/
        for newTableName in Array(tableInfo.keys){
            let query: Table = table.select(name).filter(name == newTableName)
            
            do{
                /*用新Table名稱，查詢之前是否有建立過(不是就新建，是就開始搬移資料)*/
                let oldTableNames:[String]! = try DatabaseManager.instance.databaseConnection?.prepare(query).map() {
                    row -> String in
                    
                    return try row.get(name)
                }
                
                /*0.檢查是否為新建table*/
                if oldTableNames.count == 0{
                    do {
                        /*是就直接create*/
                        try DatabaseManager.instance.databaseConnection?.run(tableInfo[newTableName]!)
                    } catch  {
                        print("create table error : \(error)")
                    }
                }
                else{
                    let oldTableName: String = oldTableNames[0]
                    
                    /*1.把原table變更為temp_table，另外再創建新table*/
                    let sqlCmd: String = String(format: "ALTER TABLE '%@' RENAME TO 'temp_%@'",oldTableName,oldTableName)
                    try DatabaseManager.instance.databaseConnection?.run(sqlCmd)
                    try DatabaseManager.instance.databaseConnection?.run(tableInfo[oldTableName]!)
                    
                    /*2.取得原table的所有欄位名稱，並且取得此次更新沒異動的欄位名稱*/
                    let oldColumnsData: Set<String> = getColumnsNames(tableName: "temp_".appending(oldTableName))
                    let newColumnsData: Set<String> = getColumnsNames(tableName: newTableName)
                    let columns:Array = Array(oldColumnsData.intersection(newColumnsData))//取得新、舊Table欄位的交集
                    
                    /*2A.新舊Table欄位名稱一致，不需搬移資料*/
                    if oldColumnsData.count == columns.count,newColumnsData.count == columns.count{//用遞移關係判斷
                        /*刪除新建資料表*/
                        let sqlCmd2: String = String(format: "DROP TABLE '%@'",oldTableName)
                        try DatabaseManager.instance.databaseConnection?.run(sqlCmd2)
                        
                        /*復原舊資料表名字*/
                        let sqlCmd3: String = String(format: "ALTER TABLE 'temp_%@' RENAME TO '%@'",oldTableName,oldTableName)
                        try DatabaseManager.instance.databaseConnection?.run(sqlCmd3)
                    }
                    /*新舊Table欄位不一致*/
                    else{
                        let cols:String = columns.joined(separator: ",")//把欄位名稱用逗號拼接起來
                        
                        /*3.把舊table的資料寫進新table中(只寫入欄位名稱沒異動的資料)*/
                        let sqlCmd2: String = String(format: "INSERT INTO %@ (%@) SELECT %@ FROM temp_%@",newTableName,cols,cols,oldTableName)
                        try DatabaseManager.instance.databaseConnection?.run(sqlCmd2)
                        
                        /*4.資料搬移完成後，刪除原table，只保留新table*/
                        let sqlCmd3: String = String(format: "DROP TABLE 'temp_%@'",oldTableName)
                        try DatabaseManager.instance.databaseConnection?.run(sqlCmd3)
                    }
                }
            }catch{
                print(error.localizedDescription)
            }
        }
    }
    
    /// 取得原Table的全部欄位名稱
    /// - Parameter tableName: 資料表名稱
    /// - Returns: 資料表全部欄位
    private func getColumnsNames(tableName: String) -> Set<String>{
        var columnsData: Set<String> = Set()//table全部欄位
        
        do{
            let columnsNames:Statement? = try DatabaseManager.instance.databaseConnection?.run("PRAGMA table_info(".appending(tableName).appending(")"))
            
            /*取出目前全部欄位名稱*/
            for columns in columnsNames! {
                if columns[1] != nil{
                    columnsData.insert(columns[1] as! String)
                }
            }
        }catch{
            print(error.localizedDescription)
        }
        
        return columnsData
    }
}
