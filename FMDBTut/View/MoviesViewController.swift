//
//  MoviesViewController.swift
//  FMDBTut
//
//  Created by Gabriel Theodoropoulos on 04/10/16.
//  Copyright © 2016 Appcoda. All rights reserved.
//

import UIKit
import SQLite

class MoviesViewController: UIViewController {

    // MARK: IBOutlet Properties
    @IBOutlet weak var tblMovies: UITableView!
    // MARK: Custom Properties
    var movieResults : [MovieResultInfo] = []
    
    // MARK: Initialization
    override func viewDidLoad() {
        super.viewDidLoad()
        tblMovies.delegate = self
        tblMovies.dataSource = self
    }

    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let results = try? MovieTableManager.instance.loadInfos() {
            movieResults = results
        }
        else {
            movieResults = []
        }
        for result in movieResults {
            result.getImageData()
        }
        tblMovies.reloadData()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
    // MARK: UITableView Methods
extension MoviesViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return movieResults.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let currentMovie = movieResults[indexPath.row]
        
        cell.textLabel?.text = currentMovie.title
        cell.imageView?.image = currentMovie.coverImg
        return cell
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100.0
    }
}
extension MoviesViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selResult = movieResults[indexPath.row]
        
        guard let movieID = selResult.movieID,
            let selMovieInfo = try? MovieTableManager.instance.select(defineId: movieID) else {
            return
        }
        
        let img = MovieTableManager.instance.getCoverImage(from: selMovieInfo)
        
        let detailVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "MovieDetailsViewController") as! MovieDetailsViewController
        detailVC.movieInfo = selMovieInfo
        navigationController?.pushViewController(detailVC, animated: true)
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle != .delete {
            return
        }
        let selResult = movieResults[indexPath.row]
        let deleteSuccess = MovieTableManager.instance.delete(info: selResult)
        if !deleteSuccess {
            return
        }
        movieResults.remove(at: indexPath.row)
        tableView.reloadData()
    }
    
}
