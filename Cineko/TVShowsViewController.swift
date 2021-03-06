//
//  TVShowsViewController.swift
//  Cineko
//
//  Created by Jovit Royeca on 01/04/2016.
//  Copyright © 2016 Jovito Royeca. All rights reserved.
//

import UIKit
import CoreData
import JJJUtils
import MBProgressHUD

class TVShowsViewController: UIViewController {
    // MARK: Outlets
    @IBOutlet weak var organizeButton: UIBarButtonItem!
    @IBOutlet weak var tableView: UITableView!
    
    // MARK: Variables
    var dynamicFetchRequest:NSFetchRequest?
    var favoritesFetchRequest:NSFetchRequest?
    var watchlistFetchRequest:NSFetchRequest?
    let tvShowGroups = ["Popular", "Top Rated", "On The Air"]
    var dynamicTitle:String?
    private var dataDict = [String: [AnyObject]]()
    
    // MARK: Actions
    @IBAction func organizeAction(sender: UIBarButtonItem) {
        let alert = UIAlertController(title: "Select", message: nil, preferredStyle: .ActionSheet)
        
        for group in tvShowGroups {
            // add a checkmark for the current group using Unicode
            let title = group == dynamicTitle ? "\u{2713} \(dynamicTitle!)" : group
            
            let handler = {(alert: UIAlertAction!) in
                self.dynamicTitle = group
                NSUserDefaults.standardUserDefaults().setValue(self.dynamicTitle, forKey: TMDBConstants.Device.Keys.TVShowsDynamic)
                NSUserDefaults.standardUserDefaults().synchronize()
                self.loadTVShowGroup()
            }
            alert.addAction(UIAlertAction(title: title, style: UIAlertActionStyle.Default, handler: handler))
        }
        
        if UIDevice.currentDevice().userInterfaceIdiom == .Pad {
            if let popover = alert.popoverPresentationController {
                popover.barButtonItem = organizeButton
                popover.permittedArrowDirections = .Any
                showDetailViewController(alert, sender:organizeButton)
            }
        } else {
            presentViewController(alert, animated: true, completion: nil)
        }
    }
    
    // MARK: Overrides
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.registerNib(UINib(nibName: "ThumbnailTableViewCell", bundle: nil), forCellReuseIdentifier: "Cell")
        
        if let dynamicTitle = NSUserDefaults.standardUserDefaults().valueForKey(TMDBConstants.Device.Keys.TVShowsDynamic) as? String {
            self.dynamicTitle = dynamicTitle
        } else {
            dynamicTitle = tvShowGroups.first
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        loadTVShowGroup()
        loadFavorites()
        loadWatchlist()
    }
    
    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        if let tableView = tableView {
            tableView.reloadData()
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showTVShowDetailsFromTVShows" {
            if let detailsVC = segue.destinationViewController as? TVShowDetailsViewController {
                let tvShow = sender as! TVShow
                detailsVC.tvShowOID = tvShow.objectID
            }
        } else if segue.identifier == "showSeeAllFromTVShows" {
            if let detailsVC = segue.destinationViewController as? SeeAllViewController {
                var title:String?
                var fetchRequest:NSFetchRequest?
                
                switch sender as! Int {
                case 0:
                    title = dynamicTitle
                    fetchRequest = dynamicFetchRequest
                case 1:
                    title = "Favorites"
                    fetchRequest = favoritesFetchRequest
                case 2:
                    title = "Watchlist"
                    fetchRequest = watchlistFetchRequest
                default:
                    ()
                }
                
                detailsVC.navigationItem.title = title
                detailsVC.fetchRequest = fetchRequest
                detailsVC.displayType = .Poster
                detailsVC.captionType = .Title
                detailsVC.view.tag = sender as! Int
                detailsVC.delegate = self
            }
        }
    }
    
    // MARK: Custom methods
    func loadTVShowGroup() {
        var path:String?
        var descriptors:[NSSortDescriptor]?
        var refreshData:String?
        
        if let tvShowGroup = dynamicTitle {
            switch tvShowGroup {
            case tvShowGroups[0]:
                path = TMDBConstants.TVShows.Popular.Path
                descriptors = [
                    NSSortDescriptor(key: "popularity", ascending: false),
                    NSSortDescriptor(key: "name", ascending: true)]
                refreshData = TMDBConstants.Device.Keys.TVShowsPopular
            case tvShowGroups[1]:
                path = TMDBConstants.TVShows.TopRated.Path
                descriptors = [
                    NSSortDescriptor(key: "voteAverage", ascending: false),
                    NSSortDescriptor(key: "name", ascending: true)]
                refreshData = TMDBConstants.Device.Keys.TVShowsTopRated
            case tvShowGroups[2]:
                path = TMDBConstants.TVShows.OnTheAir.Path
                descriptors = [
                    NSSortDescriptor(key: "name", ascending: true)]
                refreshData = TMDBConstants.Device.Keys.TVShowsOnTheAir
            default:
                return
            }
        }
        
        dynamicFetchRequest = NSFetchRequest(entityName: "TVShow")
        dynamicFetchRequest!.fetchLimit = ThumbnailTableViewCell.MaxItems
        dynamicFetchRequest!.sortDescriptors = descriptors
        
        if TMDBManager.sharedInstance.needsRefresh(refreshData!) {
            let completion = { (arrayIDs: [AnyObject], error: NSError?) in
                performUIUpdatesOnMain {
                    if let error = error {
                        TMDBManager.sharedInstance.deleteRefreshData(refreshData!)
                        JJJUtil.alertWithTitle("Error", andMessage:"\(error.userInfo[NSLocalizedDescriptionKey]!)")
                    }
            
                    self.dataDict[refreshData!] = arrayIDs
                    self.dynamicFetchRequest!.predicate = NSPredicate(format: "tvShowID IN %@", arrayIDs)
                
                    if let cell = self.tableView.cellForRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 0)) {
                        MBProgressHUD.hideHUDForView(cell, animated: true)
                    }
                    self.tableView.reloadData()
                }
            }
            
            do {
                if let cell = tableView.cellForRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 0)) {
                    MBProgressHUD.showHUDAddedTo(cell, animated: true)
                }
                try TMDBManager.sharedInstance.tvShows(path!, completion: completion)
                
            } catch {}
            
        } else {
            if let tvShowIDs = dataDict[refreshData!] as? [NSNumber] {
                dynamicFetchRequest!.predicate = NSPredicate(format: "tvShowID IN %@", tvShowIDs)
            }
        }
    }
    
    func loadFavorites() {
        favoritesFetchRequest = NSFetchRequest(entityName: "TVShow")
        favoritesFetchRequest!.fetchLimit = ThumbnailTableViewCell.MaxItems
        favoritesFetchRequest!.sortDescriptors = [
            NSSortDescriptor(key: "firstAirDate", ascending: true),
            NSSortDescriptor(key: "name", ascending: true)]
        
        if TMDBManager.sharedInstance.needsRefresh(TMDBConstants.Device.Keys.FavoriteTVShows) {
            if TMDBManager.sharedInstance.hasSessionID() {
                let completion = { (arrayIDs: [AnyObject], error: NSError?) in
                    performUIUpdatesOnMain {
                        if let error = error {
                            TMDBManager.sharedInstance.deleteRefreshData(TMDBConstants.Device.Keys.FavoriteTVShows)
                            JJJUtil.alertWithTitle("Error", andMessage:"\(error.userInfo[NSLocalizedDescriptionKey]!)")
                        }
                        
                        self.favoritesFetchRequest!.predicate = NSPredicate(format: "tvShowID IN %@", arrayIDs)
                    
                        if let cell = self.tableView.cellForRowAtIndexPath(NSIndexPath(forRow: 1, inSection: 0)) {
                            MBProgressHUD.hideHUDForView(cell, animated: true)
                        }
                        self.tableView.reloadData()
                    }
                }
                
                do {
                    if let cell = tableView.cellForRowAtIndexPath(NSIndexPath(forRow: 1, inSection: 0)) {
                        MBProgressHUD.showHUDAddedTo(cell, animated: true)
                    }
                    try TMDBManager.sharedInstance.accountFavoriteTVShows(completion)
                    
                } catch {
                    favoritesFetchRequest!.predicate = NSPredicate(format: "favorite = %@", NSNumber(bool: true))
                    if let cell = self.tableView.cellForRowAtIndexPath(NSIndexPath(forRow: 1, inSection: 0)) {
                        MBProgressHUD.hideHUDForView(cell, animated: true)
                    }
                    self.tableView.reloadData()
                }

            } else {
                favoritesFetchRequest = nil
                if let cell = self.tableView.cellForRowAtIndexPath(NSIndexPath(forRow: 1, inSection: 0)) {
                    MBProgressHUD.hideHUDForView(cell, animated: true)
                }
                self.tableView.reloadData()
            }
            
        } else {
            if TMDBManager.sharedInstance.hasSessionID() {
                favoritesFetchRequest!.predicate = NSPredicate(format: "favorite = %@", NSNumber(bool: true))
            } else {
                favoritesFetchRequest = nil
            }

            if let cell = self.tableView.cellForRowAtIndexPath(NSIndexPath(forRow: 1, inSection: 0)) {
                MBProgressHUD.hideHUDForView(cell, animated: true)
            }
        }
    }
    
    func loadWatchlist() {
        watchlistFetchRequest = NSFetchRequest(entityName: "TVShow")
        watchlistFetchRequest!.fetchLimit = ThumbnailTableViewCell.MaxItems
        watchlistFetchRequest!.sortDescriptors = [
            NSSortDescriptor(key: "firstAirDate", ascending: true),
            NSSortDescriptor(key: "name", ascending: true)]
        
        if TMDBManager.sharedInstance.needsRefresh(TMDBConstants.Device.Keys.WatchlistTVShows) {
            if TMDBManager.sharedInstance.hasSessionID() {
                let completion = { (arrayIDs: [AnyObject], error: NSError?) in
                    performUIUpdatesOnMain {
                        if let error = error {
                            TMDBManager.sharedInstance.deleteRefreshData(TMDBConstants.Device.Keys.WatchlistTVShows)
                            JJJUtil.alertWithTitle("Error", andMessage:"\(error.userInfo[NSLocalizedDescriptionKey]!)")
                        }
                        
                        self.watchlistFetchRequest!.predicate = NSPredicate(format: "tvShowID IN %@", arrayIDs)
                    
                        if let cell = self.tableView.cellForRowAtIndexPath(NSIndexPath(forRow: 2, inSection: 0)) {
                            MBProgressHUD.hideHUDForView(cell, animated: true)
                        }
                        self.tableView.reloadData()
                    }
                }
                
                do {
                    if let cell = tableView.cellForRowAtIndexPath(NSIndexPath(forRow: 2, inSection: 0)) {
                        MBProgressHUD.showHUDAddedTo(cell, animated: true)
                    }
                    try TMDBManager.sharedInstance.accountWatchlistTVShows(completion)
                    
                } catch {
                    watchlistFetchRequest!.predicate = NSPredicate(format: "watchlist = %@", NSNumber(bool: true))
                    if let cell = self.tableView.cellForRowAtIndexPath(NSIndexPath(forRow: 2, inSection: 0)) {
                        MBProgressHUD.hideHUDForView(cell, animated: true)
                    }
                    self.tableView.reloadData()
                }
                
            } else {
                watchlistFetchRequest = nil
                if let cell = self.tableView.cellForRowAtIndexPath(NSIndexPath(forRow: 2, inSection: 0)) {
                    MBProgressHUD.hideHUDForView(cell, animated: true)
                }
                self.tableView.reloadData()
            }

        } else {
            if TMDBManager.sharedInstance.hasSessionID() {
                watchlistFetchRequest!.predicate = NSPredicate(format: "watchlist = %@", NSNumber(bool: true))
            } else {
                watchlistFetchRequest = nil
            }
            
            if let cell = self.tableView.cellForRowAtIndexPath(NSIndexPath(forRow: 2, inSection: 0)) {
                MBProgressHUD.hideHUDForView(cell, animated: true)
            }
        }
    }
}

// MARK: UITableViewDataSource
extension TVShowsViewController : UITableViewDataSource {
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as! ThumbnailTableViewCell
        
        switch indexPath.row {
        case 0:
            cell.titleLabel.text = dynamicTitle
            cell.fetchRequest = dynamicFetchRequest
        case 1:
            cell.titleLabel.text = "Favorites"
            cell.fetchRequest = favoritesFetchRequest
        case 2:
            cell.titleLabel.text = "Watchlist"
            cell.fetchRequest = watchlistFetchRequest
        default:
            break
        }
        
        cell.tag = indexPath.row
        cell.displayType = .Poster
        cell.captionType = .Title
        cell.delegate = self
        cell.loadData()
        return cell
    }
}

// MARK: UITableViewDelegate
extension TVShowsViewController : UITableViewDelegate {
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return tableView.frame.size.height / 3
    }
}

// MARK: ThumbnailTableViewCellDelegate
extension TVShowsViewController : ThumbnailDelegate {
    func seeAllAction(tag: Int) {
        performSegueWithIdentifier("showSeeAllFromTVShows", sender: tag)
    }
    
    func didSelectItem(tag: Int, displayable: ThumbnailDisplayable, path: NSIndexPath) {
        performSegueWithIdentifier("showTVShowDetailsFromTVShows", sender: displayable)
    }
}
