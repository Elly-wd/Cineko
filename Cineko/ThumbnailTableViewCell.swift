//
//  ScrollingTableViewCell.swift
//  Cineko
//
//  Created by Jovit Royeca on 06/04/2016.
//  Copyright © 2016 Jovito Royeca. All rights reserved.
//

import UIKit
import CoreData
import MBProgressHUD
import SDWebImage

class ThumbnailTableViewCell: UITableViewCell {
    // MARK: Constants
    static let Height = CGFloat(180)
    static let MaxItems = 12
    static let MaxImageWidth = CGFloat(80)
    
    // MARK: Variables
    weak var delegate: ThumbnailDelegate?
    var displayType:DisplayType?
    var captionType:CaptionType?
    var showCaption = false
    var showSeeAllButton = true
    private var noDataLabel:UILabel?
    private var _fetchRequest:NSFetchRequest? = nil
    var fetchRequest:NSFetchRequest? {
        get {
            return _fetchRequest
        }
        set (aNewValue) {
            imageSizeAdjusted = false
            
            if (_fetchRequest != aNewValue) {
                _fetchRequest = aNewValue
                
                // force reset the fetchedResultsController
                if let _fetchRequest = _fetchRequest {
                    let context = CoreDataManager.sharedInstance.mainObjectContext
                    fetchedResultsController = NSFetchedResultsController(fetchRequest: _fetchRequest,
                                                                  managedObjectContext: context,
                                                                    sectionNameKeyPath: nil,
                                                                            cacheName: nil)
                }
            }
        }
    }
    lazy var fetchedResultsController: NSFetchedResultsController = {
        let context = CoreDataManager.sharedInstance.mainObjectContext
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: self.fetchRequest!,
                                                                  managedObjectContext: context,
                                                                  sectionNameKeyPath: nil,
                                                                  cacheName: nil)
        
        return fetchedResultsController
    }()
    private var shouldReloadCollectionView = false
    private var blockOperation:NSBlockOperation?
    private var fontColor:UIColor?
    private var imageSizeAdjusted = false

    // MARK: Outlets
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var seeAllButton: UIButton!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!

    // MARK: Actions
    @IBAction func seeAllAction(sender: UIButton) {
        if let delegate = delegate {
            delegate.seeAllAction(self.tag)
        }
    }
    
    // MARK: Overrides
    override func awakeFromNib() {
        super.awakeFromNib()
        
        let space = CGFloat(5.0)
        flowLayout.minimumInteritemSpacing = space
        flowLayout.minimumLineSpacing = space
        
        collectionView.registerNib(UINib(nibName: "ThumbnailCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "Cell")
        collectionView.dataSource = self
        collectionView.delegate = self
        seeAllButton.hidden = showSeeAllButton
    }
    
    // MARK: Custom methods
    func loadData() {
        var items = 0
        
        if (fetchRequest) != nil {
            do {
                try fetchedResultsController.performFetch()
            } catch {}
            fetchedResultsController.delegate = self
            
            if let sections = fetchedResultsController.sections {
                if let sectionInfo = sections.first {
                    items = sectionInfo.numberOfObjects
                }
            }
        }
        
        if items > 0 {
            if let noDataLabel = noDataLabel {
                noDataLabel.removeFromSuperview()
                self.noDataLabel = nil
            }
        } else {
            if noDataLabel == nil {
                let width = collectionView.frame.size.width/2
                let height = collectionView.frame.size.height/2
                let x = collectionView.frame.size.width/4
                let y = collectionView.frame.size.height/4
                noDataLabel = UILabel(frame: CGRectMake(x, y, width, height))
                noDataLabel!.textAlignment = .Center
                noDataLabel!.text = "No Data Found"
                noDataLabel!.font = UIFont.preferredFontForTextStyle(UIFontTextStyleHeadline)
                collectionView.addSubview(noDataLabel!)
            }
        }
        
        collectionView.reloadData()
        
        if showSeeAllButton {
            seeAllButton.hidden = items < ThumbnailTableViewCell.MaxItems
        }
    }
    
    func configureCell(cell: ThumbnailCollectionViewCell, displayable: ThumbnailDisplayable) {
        if let path = displayable.imagePath(displayType!) {
            var urlString:String?
            
            switch displayType! {
            case .Poster:
                urlString = "\(TMDBConstants.ImageURL)/\(TMDBConstants.PosterSizes[1])\(path)"
            case .Profile:
                urlString = "\(TMDBConstants.ImageURL)/\(TMDBConstants.ProfileSizes[2])\(path)"
            case .Backdrop:
                urlString = "\(TMDBConstants.ImageURL)/\(TMDBConstants.BackdropSizes[1])\(path)"
            }

            let url = NSURL(string: urlString!)
            let completedBlock = { (image: UIImage!, error: NSError!, cacheType: SDImageCacheType, url: NSURL!) in
                MBProgressHUD.hideHUDForView(cell, animated: true)
                cell.HUDAdded = false
                cell.contentMode = .ScaleToFill
                
                if let image = image {
                    if !self.imageSizeAdjusted {
                        let imageWidth = image.size.width
                        let imageHeight = image.size.height
                        let height = self.collectionView.frame.size.height
                        let newWidth = (imageWidth * height) / imageHeight
                        self.flowLayout.itemSize = CGSizeMake(newWidth, height)
                        self.imageSizeAdjusted = true
                    }
                } else {
                    var caption:String?
                    if let captionType = self.captionType {
                        caption = displayable.caption(captionType)
                    }
                    self.setDefaultImageForCell(cell, caption: caption)
                }
                
                if self.showCaption {
                    cell.addCaptionImage(displayable.caption(self.captionType!)!)
                }
            }
            
            if !cell.HUDAdded {
                let hud = MBProgressHUD.showHUDAddedTo(cell, animated: true)
                hud.opacity = 0.0
                hud.activityIndicatorColor = UIColor.blueColor()
                cell.HUDAdded = true
            }
            cell.thumbnailImage.sd_setImageWithURL(url, placeholderImage: UIImage(named: "noImage"), completed: completedBlock)
            
        } else {
            var caption:String?
            if let captionType = self.captionType {
                caption = displayable.caption(captionType)
            }
            setDefaultImageForCell(cell, caption: caption)
        }
    }
    
    func changeColor(backgroundColor: UIColor?, fontColor: UIColor?) {
        self.backgroundColor = backgroundColor
        self.fontColor = fontColor
        
        titleLabel.textColor = fontColor
        seeAllButton.setTitleColor(fontColor, forState: .Normal)
        
        if let noDataLabel = noDataLabel {
            noDataLabel.textColor = fontColor
        }
    }
    
    func setDefaultImageForCell(cell: ThumbnailCollectionViewCell, caption: String?) {
        if let image = UIImage(named: "noImage") {
            if !self.imageSizeAdjusted {
                let imageWidth = image.size.width
                let imageHeight = image.size.height
                let height = self.collectionView.frame.size.height
                let newWidth = (imageWidth * height) / imageHeight
                let width = newWidth > ThumbnailTableViewCell.MaxImageWidth ? ThumbnailTableViewCell.MaxImageWidth : newWidth
                self.flowLayout.itemSize = CGSizeMake(width, height)
            }
            
            cell.thumbnailImage.image = image
            cell.contentMode = .ScaleToFill
        }
        
        if let caption = caption {
            cell.addCaptionImage(caption)
        }
    }
}

// MARK: UICollectionViewDataSource
extension ThumbnailTableViewCell : UICollectionViewDataSource {
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if (fetchRequest) != nil,
            let sections = fetchedResultsController.sections {
            let sectionInfo = sections[section]
            return sectionInfo.numberOfObjects
            
        } else {
            return 0
        }
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("Cell", forIndexPath: indexPath) as! ThumbnailCollectionViewCell
        
        if let displayable = fetchedResultsController.objectAtIndexPath(indexPath) as? ThumbnailDisplayable {
            configureCell(cell, displayable: displayable)
        }
        
        return cell
    }
}

// MARK: UICollectionViewDelegate
extension ThumbnailTableViewCell : UICollectionViewDelegate {
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        if let delegate = delegate,
            let displayable = fetchedResultsController.objectAtIndexPath(indexPath) as? ThumbnailDisplayable {
            delegate.didSelectItem(self.tag, displayable: displayable, path: indexPath)
        }
    }
}

// MARK: NSFetchedResultsControllerDelegate
extension ThumbnailTableViewCell : NSFetchedResultsControllerDelegate {
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        shouldReloadCollectionView = false
        blockOperation = NSBlockOperation()
    }
    
    func controller(controller: NSFetchedResultsController, didChangeSection sectionInfo: NSFetchedResultsSectionInfo, atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType) {
        
        switch type {
        case .Insert:
            blockOperation!.addExecutionBlock({
                self.collectionView.insertSections(NSIndexSet(index: sectionIndex))
            })
            
        case .Delete:
            blockOperation!.addExecutionBlock({
                self.collectionView.deleteSections(NSIndexSet(index: sectionIndex))
            })
        
        case .Update:
            blockOperation!.addExecutionBlock({
                self.collectionView.reloadSections(NSIndexSet(index: sectionIndex))
            })
            
        default:
            return
        }
    }
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        
        switch type {
        case .Insert:
            blockOperation!.addExecutionBlock({
                self.collectionView.insertItemsAtIndexPaths([newIndexPath!])
            })
            
        case .Delete:
            blockOperation!.addExecutionBlock({
                self.collectionView.deleteItemsAtIndexPaths([indexPath!])
            })
            
        case .Update:
            if let indexPath = indexPath {
                if let cell = collectionView.cellForItemAtIndexPath(indexPath) {
                    
                    if let c = cell as? ThumbnailCollectionViewCell,
                        let displayable = fetchedResultsController.objectAtIndexPath(indexPath) as? ThumbnailDisplayable {
                        
                        blockOperation!.addExecutionBlock({
                            self.configureCell(c, displayable: displayable)
                        })
                    }
                }
            }
            
        case .Move:
            return
        }
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        // Checks if we should reload the collection view to fix a bug @ http://openradar.appspot.com/12954582
        if shouldReloadCollectionView {
            collectionView.reloadData()
        } else {
            collectionView.performBatchUpdates({
                if let blockOperation = self.blockOperation {
                    blockOperation.start()
                }
            }, completion:nil)
        }
    }
}

