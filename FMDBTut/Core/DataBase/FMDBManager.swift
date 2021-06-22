//
//  FMDBManager.swift
//  FMDBTut
//
//  Created by Gabriel Theodoropoulos on 07/10/16.
//  Copyright © 2016 Appcoda. All rights reserved.
//

import UIKit
import FMDB
class FMDBManager: NSObject {
    static let instance:FMDBManager = FMDBManager()
    
    private let databaseFileName:String = "FMDatabase.sqlite"
    
    /*Table欄位*/
    private let field_MovieID:String = "movieID"
    private let field_MovieTitle:String = "title"
    private let field_MovieCategory:String = "category"
    private let field_MovieYear:String = "year"
    private let field_MovieURL:String = "movieURL"
    private let field_MovieCoverURL:String = "coverURL"
    private let field_MovieWatched:String = "watched"
    private let field_MovieLikes:String = "likes"
    
    private var pathToDatabase:String = ""//.sqlite檔案路徑
    private var database:FMDatabase!
    
    override init() {
        super.init()
        
        let documentsDirectory:String = (NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString) as String
        pathToDatabase = documentsDirectory.appending("/\(databaseFileName)")
    }
    
    /**創建DB*/
    func createDatabase() -> Bool {
        var created:Bool = false
        
        /*DB檔案不存在*/
        if !FileManager.default.fileExists(atPath: pathToDatabase) {
            database = FMDatabase(path: pathToDatabase)
            
            if database != nil {
                // Open the database.
                if database.open() {
                    let createMoviesTableQuery:String = "CREATE TABLE movies ("
                        .appending("\(field_MovieID) INTEGER PRIMARY KEY AUTOINCREMENT NOT NUll,")
                        .appending("\(field_MovieTitle) TEXT NOT NULL,")
                        .appending("\(field_MovieCategory) TEXT NOT NULL,")
                        .appending("\(field_MovieYear) INTEGER NOT NULL,")
                        .appending("\(field_MovieURL) TEXT,")
                        .appending("\(field_MovieCoverURL) TEXT NOT NULL,")
                        .appending("\(field_MovieWatched) BOOL NOT NULL DEFAULT 0,")
                        .appending("\(field_MovieLikes) INTEGER NOT NULL)")
                    
                    do {
                        try database.executeUpdate(createMoviesTableQuery, values: nil)
                        created = true
                    }
                    catch {
                        print("Could not create table.")
                        print(error.localizedDescription)
                    }
                    
                    database.close()
                }
                else {
                    print("Could not open the database.")
                }
            }
        }
        
        return created
    }
    
    /***/
    func openDatabase() -> Bool {
        if database == nil {
            if FileManager.default.fileExists(atPath: pathToDatabase) {
                database = FMDatabase(path: pathToDatabase)
            }
        }
        
        if database != nil {
            if database.open() {
                return true
            }
        }
        
        return false
    }
    
    /***/
    func insertMovieData() {
        if openDatabase() {
            if let pathToMoviesFile = Bundle.main.path(forResource: "movies", ofType: "tsv") {
                do {
                    let moviesFileContents = try String(contentsOfFile: pathToMoviesFile)
                    
                    let moviesData = moviesFileContents.components(separatedBy: "\r\n")
                    
                    var query = ""
                    for movie in moviesData {
                        let movieParts = movie.components(separatedBy: "\t")
                        
                        if movieParts.count == 5 {
                            let movieTitle = movieParts[0]
                            let movieCategory = movieParts[1]
                            let movieYear = movieParts[2]
                            let movieURL = movieParts[3]
                            let movieCoverURL = movieParts[4]
                            
                            query += "insert into movies (\(field_MovieID), \(field_MovieTitle), \(field_MovieCategory), \(field_MovieYear), \(field_MovieURL), \(field_MovieCoverURL), \(field_MovieWatched), \(field_MovieLikes)) values (null, '\(movieTitle)', '\(movieCategory)', \(movieYear), '\(movieURL)', '\(movieCoverURL)', 0, 0);"
                        }
                    }
                    
                    if !database.executeStatements(query) {
                        print("Failed to insert initial data into the database.")
                        print(database.lastError(), database.lastErrorMessage())
                    }
                }
                catch {
                    print(error.localizedDescription)
                }
            }
            
            database.close()
        }
    }
    
    /***/
    func loadMovies() -> [MovieInfo]! {
        var movies: [MovieInfo]!
        
        if openDatabase() {
            let query = "select * from movies order by \(field_MovieYear) asc"
            
            do {
                let results = try database.executeQuery(query, values: nil)
                
                while results.next() {
                    let movie = MovieInfo(movieID: Int(results.int(forColumn: field_MovieID)),
                                          title: results.string(forColumn: field_MovieTitle)!,
                                          category: results.string(forColumn: field_MovieCategory),
                                          year: Int(results.int(forColumn: field_MovieYear)),
                                          movieURL: results.string(forColumn: field_MovieURL),
                                          coverURL: results.string(forColumn: field_MovieCoverURL),
                                          watched: results.bool(forColumn: field_MovieWatched),
                                          likes: Int(results.int(forColumn: field_MovieLikes))
                    )
                    
                    if movies == nil {
                        movies = [MovieInfo]()
                    }
                    
                    movies.append(movie)
                }
            }
            catch {
                print(error.localizedDescription)
            }
            
            database.close()
        }
        
        return movies
    }
    
    /***/
    func loadMovie(withID ID: Int, completionHandler: (_ movieInfo: MovieInfo?) -> Void) {
        var movieInfo: MovieInfo!
        
        if openDatabase() {
            let query = "select * from movies where \(field_MovieID)=?"
            
            do {
                let results = try database.executeQuery(query, values: [ID])
                if results.next() {
                    movieInfo = MovieInfo(movieID: Int(results.int(forColumn: field_MovieID)),
                                          title: results.string(forColumn: field_MovieTitle),
                                          category: results.string(forColumn: field_MovieCategory),
                                          year: Int(results.int(forColumn: field_MovieYear)),
                                          movieURL: results.string(forColumn: field_MovieURL),
                                          coverURL: results.string(forColumn: field_MovieCoverURL),
                                          watched: results.bool(forColumn: field_MovieWatched),
                                          likes: Int(results.int(forColumn: field_MovieLikes))
                    )
                    
                }
                else {
                    print(database.lastError())
                }
            }
            catch {
                print(error.localizedDescription)
            }
            
            database.close()
        }
        
        completionHandler(movieInfo)
    }
    
    /***/
    func updateMovie(withID ID: Int, watched: Bool, likes: Int) {
        if openDatabase() {
            let query = "update movies set \(field_MovieWatched)=?, \(field_MovieLikes)=? where \(field_MovieID)=?"
            
            do {
                try database.executeUpdate(query, values: [watched, likes, ID])
            }
            catch {
                print(error.localizedDescription)
            }
            
            database.close()
        }
    }
    
    /***/
    func deleteMovie(withID ID: Int) -> Bool {
        var deleted = false
        
        if openDatabase() {
            let query = "delete from movies where \(field_MovieID)=?"
            
            do {
                try database.executeUpdate(query, values: [ID])
                deleted = true
            }
            catch {
                print(error.localizedDescription)
            }
            
            database.close()
        }
        
        return deleted
    }
}
