//
//  CNPPopupController.h
//  CNPPopupController
//
//  Created by Carson Perrotti on 2014-09-28.
//  Copyright (c) 2014 Carson Perrotti. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CNPPopupTheme.h"

@protocol CNPPopupControllerDelegate;

@interface CNPPopupController : NSObject

@property (nonatomic, strong) NSAttributedString *popupTitle;
@property (nonatomic, strong) NSArray *contents;
@property (nonatomic, strong) NSArray *buttonTitles;
@property (nonatomic, strong) NSAttributedString *destructiveButtonTitle;

@property (nonatomic, strong) CNPPopupTheme *theme;

@property (nonatomic, weak) id <CNPPopupControllerDelegate> delegate;

- (instancetype)initWithTitle:(NSAttributedString *)popupTitle
                     contents:(NSArray *)contents
                  buttonTitles:(NSArray *)buttonTitles
       destructiveButtonTitle:(NSAttributedString *)destructiveButtonTitle;

- (void)presentPopupControllerAnimated:(BOOL)flag;
- (void)dismissPopupControllerAnimated:(BOOL)flag;

@end

@protocol CNPPopupControllerDelegate <NSObject>

@optional
- (void)popupControllerWillPresent:(CNPPopupController *)controller;
- (void)popupControllerDidPresent:(CNPPopupController *)controller;
- (void)popupController:(CNPPopupController *)controller willDismissWithButtonTitle:(NSString *)title;
- (void)popupController:(CNPPopupController *)controller didDismissWithButtonTitle:(NSString *)title;

@end
