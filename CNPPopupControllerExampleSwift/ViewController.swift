//
//  ViewController.swift
//  CNPPopupControllerExampleSwift
//
//  Created by Carson Perrotti on 2016-01-14.
//  Copyright © 2016 Carson Perrotti. All rights reserved.
//


// A big thank you to Alessandro Miliucci - lifeisfoo@gmail.com for helping with the swift example.

import UIKit

class ViewController: UIViewController {
    
    var popupController:CNPPopupController = CNPPopupController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func showPopupWithStyle(popupStyle: CNPPopupStyle) {
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = NSLineBreakMode.ByWordWrapping
        paragraphStyle.alignment = NSTextAlignment.Center
        
        let title = NSAttributedString(string: "It's A Popup!", attributes: [NSFontAttributeName: UIFont.systemFontOfSize(24), NSParagraphStyleAttributeName: paragraphStyle])
        let lineOne = NSAttributedString(string: "You can add text and images", attributes: [NSFontAttributeName: UIFont.systemFontOfSize(18), NSParagraphStyleAttributeName: paragraphStyle])
        let lineTwo = NSAttributedString(string: "With style, using NSAttributedString", attributes: [NSFontAttributeName: UIFont.systemFontOfSize(18), NSForegroundColorAttributeName: UIColor.init(colorLiteralRed: 0.46, green: 0.8, blue: 1.0, alpha: 1.0), NSParagraphStyleAttributeName: paragraphStyle])
        
        let button = CNPPopupButton.init(frame: CGRectMake(0, 0, 200, 60))
        button.setTitleColor(UIColor.whiteColor(), forState: UIControlState.Normal)
        button.titleLabel?.font = UIFont.boldSystemFontOfSize(18)
        button.setTitle("Close Me", forState: UIControlState.Normal)
        
        button.backgroundColor = UIColor.init(colorLiteralRed: 0.46, green: 0.8, blue: 1.0, alpha: 1.0)
        
        button.layer.cornerRadius = 4;
        button.selectionHandler = { button in
            self.popupController.dismissPopupControllerAnimated(true)
            print("Block for button: \(button.titleLabel?.text)")
        }
        
        let titleLabel = UILabel()
        titleLabel.numberOfLines = 0;
        titleLabel.attributedText = title
        
        let lineOneLabel = UILabel()
        lineOneLabel.numberOfLines = 0;
        lineOneLabel.attributedText = lineOne;
        
        let imageView = UIImageView.init(image: UIImage.init(named: "icon"))
        
        let lineTwoLabel = UILabel()
        lineTwoLabel.numberOfLines = 0;
        lineTwoLabel.attributedText = lineTwo;
        
        let customView = UIView.init(frame: CGRectMake(0, 0, 250, 55))
        customView.backgroundColor = UIColor.lightGrayColor()
        
        let textField = UITextField.init(frame: CGRectMake(10, 10, 230, 35))
        textField.borderStyle = UITextBorderStyle.RoundedRect
        textField.placeholder = "Custom view!"
        customView.addSubview(textField)
        
        self.popupController = CNPPopupController(contents:[titleLabel, lineOneLabel, imageView, lineTwoLabel, customView, button])
        self.popupController.theme = CNPPopupTheme.defaultTheme()
        self.popupController.theme.popupStyle = popupStyle
        self.popupController.delegate = self
        self.popupController.presentPopupControllerAnimated(true)
    }
    
    
    // Example action - TODO: replace with yours
    @IBAction func showPopupCentered(sender: AnyObject) {
        self.showPopupWithStyle(CNPPopupStyle.Centered)
    }
    @IBAction func showPopupFormSheet(sender: AnyObject) {
        self.showPopupWithStyle(CNPPopupStyle.ActionSheet)
    }
    @IBAction func showPopupFullscreen(sender: AnyObject) {
        self.showPopupWithStyle(CNPPopupStyle.Fullscreen)
    }
}

extension ViewController : CNPPopupControllerDelegate {
    
    func popupControllerWillDismiss(controller: CNPPopupController!) {
        print("Popup controller will be dismissed")
    }
    
    func popupControllerDidPresent(controller: CNPPopupController) {
        print("Popup controller presented")
    }
    
}

