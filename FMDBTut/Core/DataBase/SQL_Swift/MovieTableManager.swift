//
//  MovieTableManager.swift
//  FMDBTut
//
//  Created by APP技術部-周佳緯 on 2021/4/28.
//  Copyright © 2021 Appcoda. All rights reserved.
//

import UIKit
import SQLite


class MovieTableManager: DatabaseManager {
    static let shared = MovieTableManager()
    
    private let tableName = "movies"
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
    
    private var hadCoverDataRow = false
    
    override func createDatabase() -> Bool {
        let result = super.createDatabase()
        
        func createTable() {
            // temporary: 是否為臨時的 Table
            // ifNotExists: 是否不存在時才會建立
            // withoutRowid: 是否建立自動增長的 Id
            let createSql = moviesTable.create(temporary: false, ifNotExists: true, withoutRowid: false) { (table) in
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
            do {
                try databaseConnection?.run(createSql)
            } catch  {
                NSLog("create table error : \(error)")
            }
        }
        
        do {
            let isExists = try databaseConnection?.scalar(moviesTable.exists)
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
    public func insert(movieInfo: MovieResultInfo) {
        do {
            let sql = try moviesTable.insert(movieInfo)
            print("insert sql : \(sql.asSQL())")
            try databaseConnection?.run(sql)
        } catch  {
            NSLog("insert error : \(error.localizedDescription)")
        }
    }
    
    public func delete(info : MovieResultInfo) -> Bool  {
        let movId = Int64(info.movieID)
        let selId = Expression<Int64>(value: movId)
        let deleteQuery = moviesTable.filter(movieId == selId).delete()
        do {
            var result = false
            if let deleteResult = try databaseConnection?.run(deleteQuery) {
                result = deleteResult != 0
            }
            return result
        } catch  {
            return false
        }
    }
    
    public func update(info: MovieResultInfo) {
        do {
            let movId = Int64(info.movieID)
            let selId = Expression<Int64>(value: movId)
            let query = try moviesTable.filter(movieId == selId).update(info)
            let result = try? databaseConnection?.run(query)
            let isSuccess = result != 0
            NSLog("update success :\(isSuccess)")
        } catch  {
            NSLog("update error : \(error.localizedDescription)")
        }
    }
    
    public func loadInfos() throws -> [MovieResultInfo]? {
        do {
            try loadInfos(true)
            let savedInfos = try databaseConnection?.prepare(moviesTable).map() { (row) -> MovieResultInfo in
                return try row.decode()
            }
            return savedInfos
        } catch {
            throw error
        }
    }
    
    public func loadInfos(_ useSql: Bool = true) throws -> [MovieResultInfo]? {
        do {
            let sql = "SELECT * FROM \"\(tableName)\""
            guard let results = try databaseConnection?.prepare(sql) else {
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
            guard let requestResults = try databaseConnection?.prepare(sql) else {
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
            try databaseConnection?.run(query)
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
            try databaseConnection?.run(query)
        } catch  {
            NSLog("insert fail error : \(error.localizedDescription)")
        }
    }
}

extension MovieTableManager {
    public func getMoviesInfoArray() -> [MovieResultInfo]? {
        guard
            let moviePilePath = Bundle.main.path(forResource: "movies", ofType: "tsv"),
            let moviesFileContents = try? String(contentsOfFile: moviePilePath)
        else {
            return nil
        }
        
        let movieData = moviesFileContents.components(separatedBy: "\r\n")
        var movieInfoDict = [[String : Any?]]()
        for movieInfoStr in movieData {
            if movieInfoStr.count == 0 {
                continue
            }
            let movieInfoArray = movieInfoStr.components(separatedBy: "\t")
            var infoDict = [String : Any?]()
            
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
    func insert(title: String, category: String, year: Int, movieUrl: String? = nil, coverURL: String, watched: Bool = false, likes: Int = 0) {
        do {
            let int64Year = Int64(year)
            let int64Likes = Int64(likes)
            let convertMovieURL : Expression<String?> = Expression<String?>(value: movieUrl)
            
            let sql = moviesTable.insert(movieTitle <- title,
                                         movieCategory <- category,
                                         movieYear <- int64Year,
                                         movieURL <- convertMovieURL,
                                         movieCoverURL <- coverURL,
                                         movieWatched <- watched,
                                         movieLikes <- int64Likes)
            print("property insert sql : \(sql.asSQL())")
            try databaseConnection?.run(sql)
        } catch  {
            NSLog("insert error : \(error.localizedDescription)")
        }
    }
    
    func insert(infoArray: [MovieResultInfo]) {
        if infoArray.count == 0 {
            return
        }
        do {
            try transaction { [weak self] in
                for info in infoArray {
                    self?.insert(movieInfo: info)
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
            let savedInfos = try databaseConnection?.prepare(query).map() { (row) -> MovieResultInfo in
                return try row.decode()
            }
            return savedInfos?.first
        } catch  {
            throw error
        }
    }
    
    // 讀取第一項資料
    public func selectFirstInfo () {
        guard let row = try? databaseConnection?.pluck(moviesTable) else {
            return
        }
        do {
            let firstInfo: MovieResultInfo = try row.decode()
            NSLog("id : \(firstInfo.movieID)")
        } catch  {
            NSLog("decode error : \(error.localizedDescription)")
        }
    }
    
    /// SQL 篩選範例
    public func selectInfos() throws -> [MovieResultInfo]? {
        // 列出 title
        let query = moviesTable.filter(movieYear > 1990).order(movieId)
        do {
            let savedInfos = try databaseConnection?.prepare(query).map() { (row) -> MovieResultInfo in
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
            let result = try databaseConnection?.run(query)
            let isSuccess = result != 0
            NSLog("update success :\(isSuccess)")
        } catch  {
            NSLog("update error : \(error.localizedDescription)")
        }
    }
}

//MARK: Join 範例
extension MovieTableManager {
    /* android join 語法
     SELECT ResultSheetHeader.resultSheetID FROM ResultSheetHeader INNER JOIN ResultSheetQuestion ON ResultSheetHeader.resultSheetID = ResultSheetQuestion.resultSheetID WHERE departure= :departure AND ResultSheetQuestion.creator=:fUserID AND ResultSheetHeader.accepted != 'Y' GROUP BY ResultSheetHeader.resultSheetID
     */
    
    public func join(table: QueryType ,column: Expression<String> ,for selfColume: Expression<String>) {
        let joinInfo = table[column] == moviesTable[selfColume]
        
        let query = moviesTable.select(movieTitle).join(table, on: joinInfo).where(movieYear > 1990 && movieId == 0).group(movieTitle)
        
        NSLog("query sql : \(query.asSQL())")
    }
    
    
    public func getCoverImage(from info : MovieResultInfo) -> UIImage? {
        var resultImg : UIImage?
        
        let movieTable = MovieTableManager.shared.moviesTable
        let coverTable = CoverTableManager.shared.coverTable
        
        let movieTableCoverUrl = MovieTableManager.shared.movieCoverURL
        let coverTableCoverUrl = CoverTableManager.shared.coverURL
        
        let joinReQuestInfo : Expression<Bool> = movieTable[movieTableCoverUrl] == coverTable[coverTableCoverUrl]
        
        let whereRequest = movieTable[movieTableCoverUrl] == coverTable[coverTableCoverUrl] &&
                            coverTable[coverTableCoverUrl] == info.coverURL
        
        let selectRequest = CoverTableManager.shared.coverData
        
        let info = coverTable
                    .select(selectRequest)
                    .join(movieTable, on: joinReQuestInfo)
                    .where(whereRequest)
        do {
            guard let results = try databaseConnection?.prepare(info) else {
                return resultImg
            }
            for row in results {
                guard let imgData = try row.get(CoverTableManager.shared.coverData),
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
