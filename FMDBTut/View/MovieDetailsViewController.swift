//
//  MovieDetailsViewController.swift
//  FMDBTut
//
//  Created by Gabriel Theodoropoulos on 04/10/16.
//  Copyright © 2016 Appcoda. All rights reserved.
//

import UIKit

class MovieDetailsViewController: UIViewController {

    // MARK: IBOutlet Properties
    
    @IBOutlet weak var imgMovieCover: UIImageView!
    
    @IBOutlet weak var btnMovieTitle: UIButton!
    
    @IBOutlet weak var lblCategory: UILabel!
    
    @IBOutlet weak var lblMovieYear: UILabel!
    
    @IBOutlet weak var swWatched: UISwitch!
    
    @IBOutlet weak var stLikes: UIStepper!
    
    @IBOutlet weak var lblLikeDescription: UILabel!
    
    
    // MARK: Custom Properties
    var movieInfo: MovieResultInfo?
    
    
    // MARK: Initialization
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.setValuesToViews()
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

    
    // MARK: Custom Methods
    
    
    func setValuesToViews() {
        imgMovieCover.image = movieInfo?.coverImg
        btnMovieTitle.setTitle(movieInfo?.title, for: UIControl.State.normal)
        
        lblCategory.text = movieInfo?.category
        
        
        lblMovieYear.text = "\(movieInfo?.year ?? 0)"
        
        swWatched.isOn = movieInfo?.watched == true
        
        stLikes.value = Double(movieInfo?.likes ?? 0)
        lblLikeDescription.text = messageForLikes()
    }
    
    
    func messageForLikes() -> String {
        switch movieInfo?.likes {
        case 0:
            return "I didn't like it at all."
            
        case 1:
            return "Interesting, but not exciting."
            
        case 2:
            return "Nice movie!"
        default:
            return "I loved it!"
        }
    }
    // MARK: IBAction Methods
    
    @IBAction func updateWatchedState(_ sender: AnyObject) {
        movieInfo?.watched = swWatched.isOn
    }
    
    
    @IBAction func changeNumberOfLikes(_ sender: AnyObject) {
        movieInfo?.likes = Int(stLikes.value)
        lblLikeDescription.text = messageForLikes()
    }
    
    @IBAction func saveChanges(_ sender: AnyObject) {
        if let info = movieInfo {
            MovieTableManager.instance.update(info: info)
        }
        
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func openMovieWebpage(_ sender: AnyObject) {
        guard let urlStr = movieInfo?.movieURL,
              let url = URL(string: urlStr) else {
            return
        }
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
    
    
}
