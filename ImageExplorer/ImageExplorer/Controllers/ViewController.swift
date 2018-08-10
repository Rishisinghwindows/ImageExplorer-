//
//  ViewController.swift
//  ImageViewer
//
//  Created by Rishi Kumar on 08/08/18.
//  Copyright © 2018 Rishi Kumar. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    var photos:Photos?
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var activityController: UIActivityIndicatorView!
    var footerView:CustomFooterView?
    let footerViewReuseIdentifier = "RefreshFooterView"
    var isLoading:Bool = false
    let searchBar = UISearchBar();
    var searchText = "kittens"
    let placeHolderText = "Search"

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        collectionView.register(UINib(nibName: "CustomFooterView", bundle: nil), forSupplementaryViewOfKind: UICollectionElementKindSectionFooter, withReuseIdentifier: footerViewReuseIdentifier)
        addSearchBarOnNavigationBar()
        fetchPhotos(searchText: searchText);
    }
    
    /// MARK : - Method
    
    func fetchPhotos(searchText:String) {
        activityController.startAnimating()
        activityController.isHidden = false
        Photos.fetchPhotos(searchText: searchText) { [unowned self]  (success, photosObj, error) in
            self.activityController.stopAnimating()
            self.activityController.isHidden = true
            self.isLoading = false
            if success == true {
                if self.photos == nil {
                    self.photos = photosObj;
                }
                else {
                    for photo in (photosObj?.photo) ?? [] {
                        self.photos?.photo.append(photo);
                    }
                }
                self.collectionView.reloadData()
            }
        }
    }
    
    func addSearchBarOnNavigationBar()  {
        let searchBar = UISearchBar()
        searchBar.sizeToFit()
        searchBar.placeholder = placeHolderText
        searchBar.delegate = self
        self.navigationController?.navigationBar.topItem?.titleView = searchBar
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}

extension ViewController:UICollectionViewDataSource,UICollectionViewDelegate,UICollectionViewDelegateFlowLayout {
    
    // MARK: UICollectionViewDataSource and delegates
    func numberOfSections(in _: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_: UICollectionView, numberOfItemsInSection _: Int) -> Int {
        return photos?.photo.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell: PhotoCell = collectionView.dequeueReusableCell(withReuseIdentifier: "imageCell", for: indexPath) as! PhotoCell
        cell.setupData(info: (photos?.photo[indexPath.row])!)
        return cell
    }
    
    func collectionView(_: UICollectionView, layout _: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        return CGSize(width: self.view.bounds.size.width/3, height: self.view.bounds.size.width/3)
        
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        if isLoading {
            return CGSize.zero
        }
        return CGSize(width: collectionView.bounds.size.width, height: 55)
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionElementKindSectionFooter {
            let aFooterView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: footerViewReuseIdentifier, for: indexPath) as! CustomFooterView
            self.footerView = aFooterView
            self.footerView?.backgroundColor = UIColor.clear
            return aFooterView
        } else {
            let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: footerViewReuseIdentifier, for: indexPath)
            return headerView
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplaySupplementaryView view: UICollectionReusableView, forElementKind elementKind: String, at indexPath: IndexPath) {
        if elementKind == UICollectionElementKindSectionFooter {
            self.footerView?.prepareInitialAnimation()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didEndDisplayingSupplementaryView view: UICollectionReusableView, forElementOfKind elementKind: String, at indexPath: IndexPath) {
        if elementKind == UICollectionElementKindSectionFooter {
            self.footerView?.stopAnimate()
        }
    }
    
    
    //compute the offset and call the load method
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let contentOffset = scrollView.contentOffset.y;
        let contentHeight = scrollView.contentSize.height;
        let diffHeight = contentHeight - contentOffset;
        let frameHeight = scrollView.bounds.size.height;
        let pullHeight  = fabs(diffHeight - frameHeight);
        if pullHeight == 0.0
        {
            if (self.footerView?.isAnimatingFinal)! {
                self.isLoading = true
                self.footerView?.startAnimate()
                fetchPhotos(searchText: searchText);
            }
        }
    }
    
    //compute the scroll value and play witht the threshold to get desired effect
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let threshold   = 100.0 ;
        let contentOffset = scrollView.contentOffset.y;
        let contentHeight = scrollView.contentSize.height;
        let diffHeight = contentHeight - contentOffset;
        let frameHeight = scrollView.bounds.size.height;
        var triggerThreshold  = Float((diffHeight - frameHeight))/Float(threshold);
        triggerThreshold   =  min(triggerThreshold, 0.0)
        let pullRatio  = min(fabs(triggerThreshold),1.0);
        self.footerView?.setTransform(inTransform: CGAffineTransform.identity, scaleFactor: CGFloat(pullRatio))
        if pullRatio >= 1 {
            self.footerView?.animateFinal()
        }
    }
}

///MARK:- UiSearchbar delegates
extension ViewController: UISearchBarDelegate {
    
    public func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        searchBar.showsCancelButton = true
    }
    
    func searchBarTextDidEndEditing(_: UISearchBar) {
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.searchBar.resignFirstResponder()
        }
        searchBar.endEditing(true)
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            searchBar.resignFirstResponder()
            searchBar.endEditing(true)
        }
        searchBar.endEditing(true)
        searchBar.showsCancelButton = false
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.showsCancelButton = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.searchBar.resignFirstResponder()
        }
        if let text = searchBar.text {
            searchText = text;
            photos?.photo.removeAll()
            collectionView.reloadData()
            fetchPhotos(searchText: text);
        }
        searchBar.endEditing(true)
    }
}


