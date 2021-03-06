//
//  MovieSettingsViewController.swift
//  Cineko
//
//  Created by Jovit Royeca on 20/05/2016.
//  Copyright © 2016 Jovito Royeca. All rights reserved.
//

import UIKit
import CoreData
import Eureka
import JJJUtils
import MBProgressHUD

class MovieSettingsViewController: FormViewController {

    // MARK: Variables
    var movieOID:NSManagedObjectID?
    var lists:[List]?
    
    // MARK: Overrides
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = "Movie Settings"
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
     
        composeForm()
        
        if TMDBManager.sharedInstance.hasSessionID() {
            loadLists()
        }
    }
    
    // MARK: Custom Methods
    func setFavorite(isFavorite: Bool) {
        if let movieOID = movieOID {
            let movie = CoreDataManager.sharedInstance.mainObjectContext.objectWithID(movieOID) as! Movie
            
            let completion = { (error: NSError?) in
                performUIUpdatesOnMain {
                    if let error = error {
                        JJJUtil.alertWithTitle("Error", andMessage:"\(error.userInfo[NSLocalizedDescriptionKey]!)")
                    }
                    
                    MBProgressHUD.hideHUDForView(self.view, animated: true)
                }
            }
            
            do {
                MBProgressHUD.showHUDAddedTo(view, animated: true)
                try TMDBManager.sharedInstance.accountFavorite(movie.movieID!, mediaType: .Movie, favorite: isFavorite, completion: completion)
            } catch {
                
            }
        }
    }

    func setWatchlist(isWatchlist: Bool) {
        if let movieOID = movieOID {
            let movie = CoreDataManager.sharedInstance.mainObjectContext.objectWithID(movieOID) as! Movie
            
            let completion = { (error: NSError?) in
                performUIUpdatesOnMain {
                    if let error = error {
                        JJJUtil.alertWithTitle("Error", andMessage:"\(error.userInfo[NSLocalizedDescriptionKey]!)")
                    }
                    
                    MBProgressHUD.hideHUDForView(self.view, animated: true)
                }
            }
            
            do {
                MBProgressHUD.showHUDAddedTo(view, animated: true)
                try TMDBManager.sharedInstance.accountWatchlist(movie.movieID!, mediaType: .Movie, watchlist: isWatchlist, completion: completion)
            } catch {

            }
        }
    }

    func addMovieToList(list: List) {
        if let movieOID = movieOID {
            let movie = CoreDataManager.sharedInstance.mainObjectContext.objectWithID(movieOID) as! Movie
            
            let completion = { (error: NSError?) in
                performUIUpdatesOnMain {
                    MBProgressHUD.hideHUDForView(self.view, animated: true)
                    
                    if let error = error {
                        JJJUtil.alertWithTitle("Error", andMessage:"\(error.userInfo[NSLocalizedDescriptionKey]!)")
                    }
                }
            }
            
            do {
                MBProgressHUD.showHUDAddedTo(view, animated: true)
                try TMDBManager.sharedInstance.addMovie(movie.movieID!, toList: list.listIDInt!, completion: completion)
            } catch {
                JJJUtil.alertWithTitle("Error", andMessage:"Failed to add Movie to List.")
            }
        }
    }

    func removeMovieFromList(list: List) {
        if let movieOID = movieOID {
            let movie = CoreDataManager.sharedInstance.mainObjectContext.objectWithID(movieOID) as! Movie
            
            let completion = { (error: NSError?) in
                performUIUpdatesOnMain {
                    MBProgressHUD.hideHUDForView(self.view, animated: true)
                    
                    if let error = error {
                        JJJUtil.alertWithTitle("Error", andMessage:"\(error.userInfo[NSLocalizedDescriptionKey]!)")
                    }
                }
            }
            
            do {
                MBProgressHUD.showHUDAddedTo(view, animated: true)
                try TMDBManager.sharedInstance.removeMovie(movie.movieID!, fromList: list.listIDInt!, completion: completion)
            } catch {
                JJJUtil.alertWithTitle("Error", andMessage:"Failed to remove Movie from List.")
            }
        }
    }
    
    func loadLists() {
        if TMDBManager.sharedInstance.needsRefresh(TMDBConstants.Device.Keys.Lists) {
            let completion = { (arrayIDs: [AnyObject], error: NSError?) in
                if let error = error {
                    TMDBManager.sharedInstance.deleteRefreshData(TMDBConstants.Device.Keys.Lists)
                    performUIUpdatesOnMain {
                        JJJUtil.alertWithTitle("Error", andMessage:"\(error.userInfo[NSLocalizedDescriptionKey]!)")
                    }
                }
                
                let predicate = NSPredicate(format: "listIDInt IN %@", arrayIDs)
                if let lists = ObjectManager.sharedInstance.findObjects("List", predicate: predicate, sorters: [NSSortDescriptor(key: "name", ascending: true)]) as? [List] {
                    
                    self.lists = lists
                    performUIUpdatesOnMain {
                        self.composeForm()
                        self.addListsToForm()
                    }
                }
            }
            
            do {
                try TMDBManager.sharedInstance.lists(completion)
            } catch {
                let predicate = NSPredicate(format: "createdBy = %@ AND listIDInt != nil", TMDBManager.sharedInstance.account!)
                if let lists = ObjectManager.sharedInstance.findObjects("List", predicate: predicate, sorters: [NSSortDescriptor(key: "name", ascending: true)]) as? [List] {
                    
                    self.lists = lists
                    composeForm()
                    addListsToForm()
                }
            }
            
        } else {
            let predicate = NSPredicate(format: "createdBy = %@ AND listIDInt != nil", TMDBManager.sharedInstance.account!)
            if let lists = ObjectManager.sharedInstance.findObjects("List", predicate: predicate, sorters: [NSSortDescriptor(key: "name", ascending: true)]) as? [List] {
                
                self.lists = lists
                composeForm()
                addListsToForm()
            }
        }
    }
    
    func composeForm() {
        let hasSession = TMDBManager.sharedInstance.hasSessionID()
        let header = hasSession ? "" : "You may need to login to enable editing"
        var movie:Movie?
        
        if let movieOID = movieOID {
            movie = CoreDataManager.sharedInstance.mainObjectContext.objectWithID(movieOID) as? Movie
        }
        
        form =
            Section(header)
            <<< SwitchRow() {
                    $0.title = "Favorite"
                    $0.tag =  "Favorite"
                    $0.disabled = hasSession ? false : true
                if let favorite = movie!.favorite {
                    $0.value = favorite.boolValue && hasSession
                } else {
                    $0.value = false
                }}.onChange { row in
                    if let value = row.value {
                        self.setFavorite(value as Bool)
                    }
                }

            <<< SwitchRow() {
                    $0.title = "Watchlist"
                    $0.tag = "Watchlist"
                    $0.disabled = hasSession ? false : true
                if let watchlist = movie!.watchlist {
                    $0.value = watchlist.boolValue && hasSession
                } else {
                    $0.value = false
                }}.onChange { row in
                    if let value = row.value {
                        self.setWatchlist(value as Bool)
                    }
                }
        
            +++ Section(header: "Lists", footer: "Tap a List to Add or Remove this movie.")
    }

    func addListsToForm() {
        if let lists = lists,
           let movieOID = movieOID {
            
            let movie = CoreDataManager.sharedInstance.mainObjectContext.objectWithID(movieOID) as! Movie
            
            for list in lists {
                var checked = false
                
                if let movies = list.movies {
                    for mov in movies.allObjects {
                        let m = mov as! Movie
                        if movie.movieID == m.movieID {
                            checked = true
                            break
                        }
                    }
                }
                
                form.last!
                    <<< CheckRow() {
                            $0.title = list.name
                            $0.tag = "\(list.listIDInt)"
                            $0.value = checked
                        }.onChange { row in
                            if let value = row.value {
                                let mark = value as Bool
                                
                                if mark {
                                    self.addMovieToList(list)
                                } else {
                                    self.removeMovieFromList(list)
                                }
                            }
                        }
            }
        }
    }
}
