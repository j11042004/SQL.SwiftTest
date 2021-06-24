//
//  MovieTableManager.swift
//  FMDBTut
//
//  Created by APP技術部-周佳緯 on 2021/4/28.
//  Copyright © 2021 Appcoda. All rights reserved.
//

import UIKit
import SQLite

class MovieTableManager: NSObject {
    static let instance = MovieTableManager()
    
    /*Table名稱*/
    public let tableName = "movies"
    
    /*Table欄位*/
    public private(set) lazy var moviesTable = Table(tableName)
    public let movieId = Expression<Int64>("movieID")
    public let movieTitle = Expression<String>("title")
    public let movieCategory = Expression<String>("category")
    public let movieYear = Expression<Int64>("year")
    public let movieURL = Expression<String?>("movieURL")
    public let movieCoverURL = Expression<String>("coverURL")
    public let movieCoverData = Expression<Data?>("coverData")
    public let movieWatched = Expression<Bool>("watched")
    public let movieLikes = Expression<Int64>("likes")
    
    /**/
    private var hadCoverDataRow = false
    public var createSql:String?
    
    override init() {
        super.init()
        
        // temporary: 是否為臨時的 Table
        // ifNotExists: 是否不存在時才會建立
        // withoutRowid: 是否建立自動增長的 Id
        createSql = moviesTable.create(temporary: false, ifNotExists: true, withoutRowid: false) {
            table in
            
            table.column(movieId, primaryKey: .autoincrement)
            table.column(movieTitle)
            table.column(movieCategory)
            table.column(movieYear)
            table.column(movieURL)
            table.column(movieCoverURL)
            
            // 若是由 Codable Modle 會有 nil 的 欄位要在此給預設值
            table.column(movieWatched, defaultValue: false)
            table.column(movieLikes, defaultValue: 0)

            NSLog("\(movieWatched.expression.asSQL())")
        }
    }
    
    /**建立Table*/
    func createDatabase() -> Bool {
        let result:Bool = DatabaseManager.instance.created
       
        func createTable() {
            do {
                /*create table*/
                try DatabaseManager.instance.databaseConnection?.run(createSql!)
            } catch  {
                NSLog("create table error : \(error)")
            }
        }
        
        do {
            let isExists:Bool? = try DatabaseManager.instance.databaseConnection?.scalar(moviesTable.exists)//該Table是否已成功創建
            
            /*Table不存在，重跑一次方法*/
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

extension MovieTableManager {
    /**新增一筆資料*/
    public func insert(movieInfo: MovieResultInfo) throws {
        do {
            let sql:Insert = try moviesTable.insert(movieInfo)
            
            try DatabaseManager.instance.databaseConnection?.run(sql)
        } catch  {
            throw error
        }
    }
    
    /**刪除一筆資料(以pkey為刪除條件)*/
    public func delete(info : MovieResultInfo) -> Bool  {
        let movId:Int64 = Int64(info.movieID)
        let selId:Expression<Int64> = Expression<Int64>(value: movId)
        let deleteQuery:Delete = moviesTable.filter(movieId == selId).delete()
        
        var result = false
        
        do {
            if let deleteResult = try DatabaseManager.instance.databaseConnection?.run(deleteQuery) {
                result = deleteResult != 0
            }
        } catch  {
            print(String(format: "delete error:%@",error.localizedDescription))
        }
        
        return result
    }
    
    /**更新一筆資料*/
    public func update(info: MovieResultInfo) {
        do {
            let movId = Int64(info.movieID)
            let selId = Expression<Int64>(value: movId)
            let query = try moviesTable.filter(movieId == selId).update(info)
            let result = try? DatabaseManager.instance.databaseConnection?.run(query)
            let isSuccess = result != 0
            
            NSLog("update success :\(isSuccess)")
        } catch  {
            NSLog("update error : \(error.localizedDescription)")
        }
    }
    
    /**查詢全部資料*/
    public func loadInfos() throws -> [MovieResultInfo]? {
        do {
            let savedInfos = try DatabaseManager.instance.databaseConnection?.prepare(moviesTable).map() {
                row -> MovieResultInfo in
                
                return try row.decode()
            }
            
            return savedInfos
        } catch {
            throw error
        }
    }
    
    
    //MARK: - SQL
    /**新增單筆資料*/
    func insertInfo(info: MovieResultInfo) throws {
        let title:String = info.title
        let category:String = info.category
        let year:String = String(info.year)
        let movieUrl:String = info.movieURL
        let coverURL:String = info.coverURL
        let watched:String = String(info.watched == true)
        let likes:String = String(info.likes == nil ? 0 : info.likes!)
        
//        let sql = "INSERT INTO \"\(tableName)\" (\(movieTitle.asSQL()), \(movieCategory.asSQL()), \(movieYear.asSQL()), \(movieURL.asSQL()), \(movieCoverURL.asSQL()), \(movieWatched.asSQL()), \(movieLikes.asSQL())) VALUES ('\(title)', '\(category)', \(year), '\(movieUrl)', '\(coverURL)', \(watched), \(likes))"
        let sql:String = "INSERT INTO ".appending(tableName).appending(" (")
            .appending(movieTitle.asSQL()).appending(",")
            .appending(movieCategory.asSQL()).appending(",")
            .appending(movieYear.asSQL()).appending(",")
            .appending(movieURL.asSQL()).appending(",")
            .appending(movieCoverURL.asSQL()).appending(",")
            .appending(movieWatched.asSQL()).appending(",")
            .appending(movieLikes.asSQL()).appending(")")
            .appending(" VALUES (")
            .appending("'").appending(title).appending("',")
            .appending("'").appending(category).appending("',")
            .appending(year).appending(",")
            .appending("'").appending(movieUrl).appending("',")
            .appending("'").appending(coverURL).appending("',")
            .appending(watched).appending(",")
            .appending(likes).appending(");")
        
        do {
            try DatabaseManager.instance.databaseConnection?.run(sql)
        } catch  {
            throw error
        }
    }
    
    /**刪除資料*/
    public func deleteInfo(info : MovieResultInfo) throws -> Bool  {
        guard let infoId = info.movieID else {
            return false
        }
        
//        let sql = "DELETE FROM \"\(tableName)\" WHERE (\(movieId.asSQL()) = \(infoId))"
        let sql:String = "DELETE FROM ".appending(tableName).appending(" WHERE ")
            .appending(movieId.asSQL()).appending(" = '").appending(String(infoId)).appending("'")
        
        do {
            try DatabaseManager.instance.databaseConnection?.run(sql)
            
            if let handle = DatabaseManager.instance.databaseConnection?.handle {
                let isChange = sqlite3_changes(handle)
                
                return isChange != 0
            }
            
            return false
        } catch  {
            throw error
        }
    }
    
    /**修改單筆資料*/
    func updateInfo(info: MovieResultInfo) throws {
        let `id`:String = String(info.movieID)
        let title:String = info.title
        let category:String = info.category
        let year:String = String(info.year)
        let movieUrl:String = info.movieURL
        let coverURL:String = info.coverURL
        let watched:String = String(info.watched == true)
        let likes:String = String(info.likes == nil ? 0 : info.likes!)
        
//        let sql = "UPDATE \"\(tableName)\" SET \(movieId.asSQL()) = \(id), \(movieTitle.asSQL()) = '\(title)', \(movieCategory.asSQL()) = '\(category)', \(movieYear.asSQL()) = \(year), \(movieURL.asSQL()) = '\(movieUrl)', \(movieCoverURL.asSQL()) = '\(coverURL)', \(movieWatched.asSQL()) = \(watched), \(movieLikes.asSQL()) = \(likes) WHERE (\(movieId.asSQL()) = \(id))"
        let sql:String = "UPDATE ".appending(tableName).appending(" SET ")
            .appending(movieId.asSQL()).appending(" = ").appending(`id`).appending(", ")
            .appending(movieTitle.asSQL()).appending(" = ").appending("'").appending(title).appending("', ")
            .appending(movieCategory.asSQL()).appending(" = ").appending("'").appending(category).appending("', ")
            .appending(movieYear.asSQL()).appending(" = ").appending(year).appending(", ")
            .appending(movieURL.asSQL()).appending(" = ").appending("'").appending(movieUrl).appending("', ")
            .appending(movieCoverURL.asSQL()).appending(" = ").appending("'").appending(coverURL).appending("', ")
            .appending(movieWatched.asSQL()).appending(" = ").appending(watched).appending(", ")
            .appending(movieLikes.asSQL()).appending(" = ").appending(likes).appending(" ")
            .appending("WHERE ")
            .appending(movieId.asSQL()).appending(" = ").appending(`id`)
        do {
            try DatabaseManager.instance.databaseConnection?.run(sql)
        } catch  {
            throw error
        }
    }
    
    /**查詢全部資料*/
    public func loadInfoArray(_ useSql: Bool = true) throws -> [MovieResultInfo]? {
        do {
//            let sql = "SELECT * FROM \"\(tableName)\""
            let sql:String = "SELECT * FROM ".appending(tableName)
            
            guard let results = try DatabaseManager.instance.databaseConnection?.prepare(sql) else {
                return nil
            }
            
            let boolColumnName = movieWatched.asSQL().replacingOccurrences(of: "\"", with: "")
            var infoDicts = [[String : Any?]]()
            
            for row in results {
                var infoDict = [String : Any?]()
                
                for (index, name) in results.columnNames.enumerated() {
                    if boolColumnName == name {
                        let boolValue = row[index] as? Bool
                        infoDict[name] = boolValue
                    }
                    else {
                        let columnValue = row[index]
                        infoDict[name] = columnValue
                    }
                }
                
                infoDicts.append(infoDict)
            }
            
            let infosData = try JSONSerialization.data(withJSONObject: infoDicts, options: .prettyPrinted)
            let movieInfos = try JSONDecoder().decode([MovieResultInfo].self, from: infosData)
            
            NSLog("movieInfos : \(movieInfos)")
            
            return movieInfos
        } catch {
            NSLog("loadInfos error : \(error)")
            throw error
        }
    }
}

extension MovieTableManager {
    // 執行一般 SQL 取得結果
    private func run(sql: String) -> [[Any?]]? {
        do {
            guard let requestResults = try DatabaseManager.instance.databaseConnection?.prepare(sql) else {
                return nil
            }
            var resultArray = [[Any?]]()
            
            for (_, element) in requestResults.enumerated() {
                resultArray.append(element)
            }
            return resultArray
        } catch  {
            NSLog("run sql Error : \(error.localizedDescription)")
            return nil
        }
    }
}
//MARK: - Table與 DataBase 欄位相關
extension MovieTableManager {
    /// 確認 Table 是否包含特定 Row
    /// - Parameter row: 指定的 Row class
    private func checkTableHad<T>(row : Expression<T>) -> Bool {
        if hadCoverDataRow {
            return hadCoverDataRow
        }
        var isContain = false
        var templete = movieCoverData.template
        templete = templete.replacingOccurrences(of: "\"", with: "")
        // 取得 Table 所有欄位
        let query = "PRAGMA table_info(movies)"
        guard let rowInfosArray = run(sql: query) else {
            hadCoverDataRow = isContain
            return isContain
        }
        
        for rowInfos in rowInfosArray {
            for info in rowInfos {
                guard let infoStr = info as? String else {
                    continue
                }
                guard infoStr == templete else {
                    continue
                }
                isContain = true
                break
            }
        }
        
        hadCoverDataRow = isContain
        
        return isContain
    }
    
    //MARK: 新增 Row 欄位
    private func addNewColumn<T : Value>(column : Expression<T?>, defaultValue : T?) {
        if checkTableHad(row: movieCoverData) {
            return
        }
        
        do {
            let query = moviesTable.addColumn(column, defaultValue: defaultValue)
            try DatabaseManager.instance.databaseConnection?.run(query)
        } catch  {
            NSLog("insert fail error : \(error.localizedDescription)")
        }
    }
    
    private func addNewColumn<T : Value>(column : Expression<T>, defaultValue : T) {
        if checkTableHad(row: movieCoverData) {
            return
        }
        
        do {
            let query = moviesTable.addColumn(column, defaultValue: defaultValue)
            try DatabaseManager.instance.databaseConnection?.run(query)
        } catch  {
            NSLog("insert fail error : \(error.localizedDescription)")
        }
    }
}

extension MovieTableManager {
    /**取得假資料*/
    public func getMoviesInfoArray() -> [MovieResultInfo]? {
        guard
            let movieFilePath:String = Bundle.main.path(forResource: tableName, ofType: "tsv"),
            let moviesFileContents:String = try? String(contentsOfFile: movieFilePath)
        else {
            return nil
        }
        
        let movieData:[String] = moviesFileContents.components(separatedBy: "\r\n")
        var movieInfoDict:[[String:Any?]] = [[String:Any?]]()
        
        for movieInfoStr in movieData {
            if movieInfoStr.count == 0 {
                continue
            }
            
            let movieInfoArray:[String] = movieInfoStr.components(separatedBy: "\t")
            var infoDict:[String:Any?] = [String:Any?]()
            
            infoDict["title"] = movieInfoArray[0]
            infoDict["category"] = movieInfoArray[1]
            infoDict["year"] = Int(movieInfoArray[2])
            infoDict["movieURL"] = movieInfoArray[3]
            infoDict["coverURL"] = movieInfoArray[4]
            
            movieInfoDict.append(infoDict)
        }
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: movieInfoDict, options: .prettyPrinted)
            let resultInfoArray = try JSONDecoder().decode([MovieResultInfo].self, from: jsonData)
            
            return resultInfoArray
        } catch  {
            NSLog("change error : \(error.localizedDescription)")
            return nil
        }
    }
}

//MARK: - 新增資料
extension MovieTableManager {
    func insert(infoArray: [MovieResultInfo]) {
        if infoArray.count == 0 {
            return
        }
        
        do {
            try DatabaseManager.instance.transaction {
                [weak self] in
                
                for info in infoArray {
                    do {
                        try self?.insert(movieInfo: info)
                    } catch  {
                        
                    }
                }
            }
        } catch  {
            
        }
    }
}
//MARK: 讀取篩選資料
extension MovieTableManager {
    /// 取得指定的 id 資料
    public func select(defineId : Int) throws -> MovieResultInfo? {
        let willSelId : Int64 = Int64(defineId)
        
        let query = moviesTable.filter(movieId == willSelId)
        do {
            let savedInfos = try DatabaseManager.instance.databaseConnection?.prepare(query).map() { (row) -> MovieResultInfo in
                return try row.decode()
            }
            return savedInfos?.first
        } catch  {
            throw error
        }
    }
    
    // 讀取第一項資料
    public func selectFirstInfo () {
        guard let row = try? DatabaseManager.instance.databaseConnection?.pluck(moviesTable) else {
            return
        }
        do {
            let firstInfo: MovieResultInfo = try row.decode()
            NSLog("id : \(String(describing: firstInfo.movieID))")
        } catch  {
            NSLog("decode error : \(error.localizedDescription)")
        }
    }
    
    /// SQL 篩選範例
    public func selectInfos() throws -> [MovieResultInfo]? {
        // 列出 title
        let query = moviesTable.filter(movieYear > 1990).order(movieId)
        do {
            let savedInfos = try DatabaseManager.instance.databaseConnection?.prepare(query).map() { (row) -> MovieResultInfo in
                return try row.decode()
            }
            return savedInfos
        } catch  {
            throw error
        }
    }
}

//MARK:- 更新資料
extension MovieTableManager {
    public func update(info: MovieResultInfo, coverData: Data) {
        // 若無包含 不更新 Data
        if !checkTableHad(row: movieCoverData) {
            return
        }
        do {
            let selId = Int64(info.movieID)
            
            let query = moviesTable.filter(movieId == selId).update(
                movieCoverData <- coverData,
                movieTitle <- info.title)
            let result = try DatabaseManager.instance.databaseConnection?.run(query)
            let isSuccess = result != 0
            NSLog("update success :\(isSuccess)")
        } catch  {
            NSLog("update error : \(error.localizedDescription)")
        }
    }
}

//MARK: Join 範例
extension MovieTableManager {
    /*
     android join 語法
     
     SELECT
        ResultSheetHeader.resultSheetID
     FROM
        ResultSheetHeader
     INNER JOIN
        ResultSheetQuestion
     ON
        ResultSheetHeader.resultSheetID = ResultSheetQuestion.resultSheetID
     WHERE
        departure= :departure
     AND
        ResultSheetQuestion.creator=:fUserID
     AND
        ResultSheetHeader.accepted != 'Y'
     GROUP BY
        ResultSheetHeader.resultSheetID
     */
    
    public func join(table: QueryType ,column: Expression<String> ,for selfColume: Expression<String>) {
        let joinInfo:Expression<Bool> = table[column] == moviesTable[selfColume]
        
        let query:Table = moviesTable.select(movieTitle).join(.inner, table, on: joinInfo)
                    .where(movieYear > 1990 && movieId == 0).group(movieTitle)
        
        NSLog("query sql : \(query.asSQL())")
    }
    
    /**取得電影海報圖片資料*/
    public func getCoverImage(from info : MovieResultInfo) -> UIImage? {
        var resultImg : UIImage?
        
        /*要結合的Table*/
        let movieTable:Table = MovieTableManager.instance.moviesTable
        let coverTable:Table = CoverTableManager.instance.coverTable
        
        /*join欄位*/
        let movieTableCoverUrl:Expression<String> = MovieTableManager.instance.movieCoverURL
        let coverTableCoverUrl:Expression<String> = CoverTableManager.instance.coverURL
        
        /*結合條件*/
        let joinReQuestInfo:Expression<Bool> = movieTable[movieTableCoverUrl] == coverTable[coverTableCoverUrl]
        
        /*condition*/
        let whereRequest:Expression<Bool> = movieTable[movieTableCoverUrl] == coverTable[coverTableCoverUrl] &&
                            coverTable[coverTableCoverUrl] == info.coverURL
        
        let selectRequest:Expression<Data?> = CoverTableManager.instance.coverData
        
        let info:Table = coverTable
                    .select(selectRequest)//查詢欄位
                    .join(movieTable, on: joinReQuestInfo)//結合條件
                    .where(whereRequest)//condition
        
        do {
            guard let results = try DatabaseManager.instance.databaseConnection?.prepare(info) else {
                return resultImg
            }
            
            for row in results {
                guard let imgData = try row.get(CoverTableManager.instance.coverData),
                      let img = UIImage(data: imgData)
                else { continue }
                resultImg = img
                
                break
            }
            
            return resultImg
        } catch  {
            NSLog("error : \(error)")
        }
        
        return resultImg
    }
}
