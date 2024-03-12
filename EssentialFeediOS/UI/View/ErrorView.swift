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
        get { isVisible ? messageLabel.text : nil }
        set { setMessageAnimated(newValue) }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        alpha = 0
    }
    
    private var isVisible: Bool {
        return alpha > 0
    }
    
    private func setMessageAnimated(_ message: String?) {
        if let message = message {
            showAnimated(message)
        } else {
            hideMessageAnimated()
        }
    }
    
    private func showAnimated(_ message: String) {
        messageLabel.text = message
        UIView.animate(withDuration: 0.25) {
            self.alpha = 1
        }
    }
    
    private func hideMessageAnimated() {
        UIView.animate(
            withDuration: 0.25,
            animations: { [weak self] in self?.alpha = 0 },
            completion: { [weak messageLabel] completed in
                if completed { messageLabel?.text = nil }
            }
        )
    }
}
