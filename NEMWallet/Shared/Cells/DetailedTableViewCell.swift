//
//  DetailedTableViewCell.swift
//  NemIOSClient
//
//  Created by Lyubomir Dominik on 16.10.15.
//  Copyright © 2015 Artygeek. All rights reserved.
//

import UIKit

protocol DetailedTableViewCellDelegate: class
{
    func showDetailsForCell(_ cell: DetailedTableViewCell)
    func hideDetailsForCell(_ cell: DetailedTableViewCell)
}

class DetailedTableViewCell: UITableViewCell {
    
    // MARK: internal variables
    
    internal let _detailedView: UIView? = UIView(frame: CGRect.zero)
    
    // MARK: properties
    
    weak var detailDelegate :DetailedTableViewCellDelegate?
    
    var detailsIsShown :Bool {
        get {
            return _detailsIsShown ?? false
        }
        
        set {
            if _detailsIsShown == nil
            {
                _detailsIsShown = newValue
                layoutSubviews()
                return
            }
            
            let duration = (_detailsIsShown == newValue) ? 0.01 : 0.2
            _detailsIsShown = newValue
            
            UIView.animate(withDuration: duration, animations: { () -> Void in
                self.layoutSubviews()
            }) 
        }
    }
    
    // MARK: private variables
    
    fileprivate var _detailsIsShown : Bool? = nil
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.addSubview(_detailedView!)
        
        
        let swipeRecognizerRight = UISwipeGestureRecognizer(target: self, action: #selector(DetailedTableViewCell.handleSwipeGesturesRight(_:)))
        swipeRecognizerRight.direction = .right
        self.addGestureRecognizer(swipeRecognizerRight)
        
        let swipeRecognizerLeft = UISwipeGestureRecognizer(target: self, action: #selector(DetailedTableViewCell.handleSwipeGesturesLeft(_:)))
        swipeRecognizerLeft.direction = .left
        self.addGestureRecognizer(swipeRecognizerLeft)
        
        
    }
    
    // MARK: layout
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if detailsIsShown {
            _detailedView?.frame = CGRect(x: self.frame.width - _detailedView!.frame.width, y: 0, width: _detailedView!.frame.width, height: self.frame.height)
        } else {
            _detailedView?.frame = CGRect(x: self.frame.width, y: 0, width: 40, height: self.frame.height)
        }
        
        contentView.frame = CGRect(x: 0, y: 0, width: _detailedView!.frame.origin.x , height: self.frame.height)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    // MARK: GestureRecogniser Methods
    
    func handleSwipeGesturesLeft(_ sender: UISwipeGestureRecognizer)
    {
        if !detailsIsShown {
            self.detailDelegate?.showDetailsForCell(self)
        }
    }
    
    func handleSwipeGesturesRight(_ sender: UISwipeGestureRecognizer)
    {
        if detailsIsShown {
            self.detailDelegate?.hideDetailsForCell(self)
        }
    }
}
