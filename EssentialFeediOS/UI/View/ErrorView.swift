//
//  ErrorView.swift
//  EssentialFeediOS
//
//  Created by Antonio on 12/03/24.
//

import UIKit

final class ErrorView: UIView {
    @IBOutlet private var messageLabel: UILabel!
    
    var message: String? {
        get { messageLabel.text }
        set { messageLabel.text = newValue }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        message = nil
    }
}
