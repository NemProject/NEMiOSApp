//
//  TransactionMessageTableViewCell.swift
//
//  This file is covered by the LICENSE file in the root of this project.
//  Copyright (c) 2016 NEM
//

import UIKit

/// All available types for the message table view cell.
enum MessageCellType {
    case incoming
    case outgoing
    case processing
}

/// Represents a message/transaction with a correspondent in the transaction messages view controller.
class TransactionMessageTableViewCell: DetailedTableViewCell {

    // MARK: - Cell Properties
    
    var cellType: MessageCellType!
    var transaction: TransferTransaction! {
        didSet {
            updateCell()
        }
    }
    
    fileprivate let transactionDateLabel = UILabel()
    fileprivate let transactionMessageTextView = UITextView()
    fileprivate let infoTopLabel = UILabel()
    fileprivate let infoCenterLabel = UILabel()
    fileprivate let infoBottomLabel = UILabel()
    fileprivate let incomingColor = UIColor(red: 229.0/255.0, green: 229.0/255.0, blue: 234.0/255.0, alpha: 1)
    fileprivate let outgoingColor = UIColor(red: 90.0/255.0, green: 179.0/255.0, blue: 232.0/255.0, alpha: 1)
    
    // MARK: - Cell Lifecycle
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        addSubview(transactionMessageTextView)
        contentView.addSubview(transactionDateLabel)
        _detailedView?.addSubview(infoTopLabel)
        _detailedView?.addSubview(infoCenterLabel)
        _detailedView?.addSubview(infoBottomLabel)
        
        updateCellAppearance()
    }
    
    override func layoutSubviews() {
        
        infoTopLabel.frame.size = CGSize(width: 80, height: 20)
        infoTopLabel.frame.origin = CGPoint.zero
        infoCenterLabel.frame.size = CGSize(width: 80, height: 20)
        infoCenterLabel.frame.origin = CGPoint(x: 0, y: 20)
        infoBottomLabel.frame.size = CGSize(width: 80, height: 20)
        infoBottomLabel.frame.origin = CGPoint(x: 0, y: 40)
        _detailedView?.frame.size = CGSize(width: 80, height: 60)
        
        super.layoutSubviews()
        
        transactionDateLabel.frame.size.width = contentView.frame.width
        transactionDateLabel.sizeToFit()
        transactionDateLabel.frame.size.width = contentView.frame.width - 20
        
        switch cellType! {
        case .incoming :
            transactionDateLabel.frame.origin.x = 20
            transactionMessageTextView.frame.size.width = contentView.frame.size.width * 0.75
            transactionMessageTextView.sizeToFit()
            transactionMessageTextView.frame.origin = CGPoint(x: 15, y: transactionDateLabel.frame.height + 5)
            transactionMessageTextView.frame.size = CGSize(width: min(contentView.frame.size.width * 0.75, transactionMessageTextView.frame.size.width), height: transactionMessageTextView.frame.size.height)
            
        case .outgoing :
            transactionDateLabel.frame.origin.x = 0
            transactionMessageTextView.frame.size.width = contentView.frame.size.width * 0.75
            transactionMessageTextView.sizeToFit()
            transactionMessageTextView.frame.size = CGSize(width: min(contentView.frame.size.width * 0.75, transactionMessageTextView.frame.size.width), height: transactionMessageTextView.frame.size.height)
            transactionMessageTextView.frame.origin = CGPoint(x: contentView.frame.size.width - transactionMessageTextView.frame.size.width - 15, y: transactionDateLabel.frame.height + 5)

        case .processing :
            transactionDateLabel.frame.size.width = contentView.frame.width
            transactionMessageTextView.frame.size.width = contentView.frame.size.width - CGFloat(30)
            transactionMessageTextView.sizeToFit()
            transactionMessageTextView.frame.size.width = contentView.frame.size.width - CGFloat(30)
            transactionMessageTextView.frame.origin = CGPoint(x: 15, y: transactionDateLabel.frame.height + 5)
        }
    }
    
    // MARK: - Cell Helper Methods
    
    /// Updates the table view cell with the provided transaction data.
    fileprivate func updateCell() {
        
        var textColor = UIColor.black
        
        switch cellType! {
        case .incoming:
            transactionDateLabel.textAlignment = NSTextAlignment.left
            transactionMessageTextView.backgroundColor = incomingColor
            textColor = UIColor.black
        case .outgoing:
            transactionDateLabel.textAlignment = NSTextAlignment.right
            transactionMessageTextView.backgroundColor = outgoingColor
            textColor = UIColor.white
        case .processing:
            transactionDateLabel.textAlignment = NSTextAlignment.center
            transactionMessageTextView.backgroundColor = incomingColor
            textColor = UIColor.black
        }
        
        var message = transaction.message?.message == "" || transaction.message?.message == nil ? "" : transaction.message?.message
        var amount = String()
        if transaction.amount > 0 {
            
            var symbol = String()
            if transaction.transferType == .incoming {
                symbol = "+"
            } else {
                symbol = "-"
            }
            
            amount = "\(symbol)\((transaction.amount / 1000000).format()) XEM" 
            
        } else {
            if message == "" {
                message = "EMPTY_MESSAGE".localized()
            }
        }
        
        if message! != "" && transaction.amount > 0 {
            amount = "\n" + amount
        }
        
        let messageAttributedString = NSMutableAttributedString(string: message!, attributes: [NSForegroundColorAttributeName: textColor, NSFontAttributeName: UIFont.systemFont(ofSize: 13, weight: UIFontWeightRegular)])
        let amountAttributedString = NSMutableAttributedString(string: amount, attributes: [NSForegroundColorAttributeName: textColor,NSFontAttributeName: UIFont.systemFont(ofSize: 15, weight: UIFontWeightMedium)])
        messageAttributedString.append(amountAttributedString)
        
        var date = String()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm dd.MM.yy"
        let timeStamp = Double(transaction.timeStamp)
        date = dateFormatter.string(from: Date(timeIntervalSince1970: Constants.genesisBlockTime + timeStamp))
        
        setMessage(messageAttributedString)
        setDate(date)
        
        layoutSubviews()
    }
    
    /// Updates the appearance of the table view cell.
    fileprivate func updateCellAppearance() {
        
        transactionDateLabel.numberOfLines = 1
        transactionDateLabel.font = UIFont.systemFont(ofSize: 10, weight: UIFontWeightRegular)
        
        transactionMessageTextView.isScrollEnabled = false
        transactionMessageTextView.layer.cornerRadius = 5
        transactionMessageTextView.clipsToBounds = true
        transactionMessageTextView.isEditable = false
        transactionMessageTextView.textContainerInset = UIEdgeInsetsMake(8, 5, 8, 5)
        
        infoTopLabel.numberOfLines = 1
        infoTopLabel.font = UIFont(name: "HelveticaNeue-Light", size: 10)
        
        infoCenterLabel.numberOfLines = 1
        infoCenterLabel.font = UIFont(name: "HelveticaNeue-Light", size: 10)
        
        infoBottomLabel.numberOfLines = 1
        infoBottomLabel.font = UIFont(name: "HelveticaNeue-Light", size: 10)
    }
    
    /// Updates the date label with the provided date and calls layoutSubviews.
    fileprivate func setDate(_ date: String) {
        transactionDateLabel.text = date
        layoutSubviews()
    }
    
    /// Updates the message label with the provided message/amount and calls layoutSubviews.
    fileprivate func setMessage(_ message: NSAttributedString) {
        transactionMessageTextView.attributedText = message
        layoutSubviews()
    }
    
    /// Updates the details labels with the provided details.
    open func setDetails(_ topInformation: NSAttributedString?, centerInformation: NSAttributedString?, bottomInformation: NSAttributedString?) {
        infoTopLabel.attributedText = topInformation
        infoCenterLabel.attributedText = centerInformation
        infoBottomLabel.attributedText = bottomInformation
    }
}
