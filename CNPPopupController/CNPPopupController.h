//
//  CNPPopupController.h
//  CNPPopupController
//
//  Created by Carson Perrotti on 2014-09-28.
//  Copyright (c) 2014 Carson Perrotti. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol CNPPopupControllerDelegate;
@class CNPPopupTheme, CNPPopupButtonItem;

@interface CNPPopupController : NSObject

@property (nonatomic, strong) NSAttributedString *popupTitle;
@property (nonatomic, strong) NSArray *contents;
@property (nonatomic, strong) NSArray *buttonItems;
@property (nonatomic, strong) CNPPopupButtonItem *destructiveButtonItem;
@property (nonatomic, strong) CNPPopupTheme *theme;

@property (nonatomic, weak) id <CNPPopupControllerDelegate> delegate;

- (instancetype)initWithTitle:(NSAttributedString *)popupTitle
                     contents:(NSArray *)contents
                 buttonItems:(NSArray *)buttonItems
       destructiveButtonItem:(CNPPopupButtonItem *)destructiveButtonItem;

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

// CNPPopupStyle: Controls how the popup looks once presented
typedef NS_ENUM(NSUInteger, CNPPopupStyle) {
    CNPPopupStyleActionSheet = 0, // Displays the popup similar to an action sheet from the bottom.
    CNPPopupStyleCentered, // Displays the popup in the center of the screen.
    CNPPopupStyleFullscreen // Displays the popup similar to a fullscreen viewcontroller.
};

// CNPPopupPresentationStyle: Controls how the popup is presented
typedef NS_ENUM(NSInteger, CNPPopupPresentationStyle) {
    CNPPopupPresentationStyleFadeIn = 0,
    CNPPopupPresentationStyleSlideInFromTop,
    CNPPopupPresentationStyleSlideInFromBottom,
    CNPPopupPresentationStyleSlideInFromLeft,
    CNPPopupPresentationStyleSlideInFromRight
};

// CNPPopupMaskType
typedef NS_ENUM(NSInteger, CNPPopupMaskType) {
    CNPPopupMaskTypeNone = 0, // Allow interaction with underlying views.
    CNPPopupMaskTypeClear, // Don't allow interaction with underlying views.
    CNPPopupMaskTypeDimmed, // Don't allow interaction with underlying views, dim background.
};

typedef void(^SelectionHandler) (CNPPopupButtonItem *item);

@interface CNPPopupButtonItem : NSObject

@property (nonatomic, strong) NSAttributedString *buttonTitle;
@property (nonatomic, strong) UIColor *backgroundColor;
@property (nonatomic, strong) UIColor *borderColor;
@property (nonatomic, assign) CGFloat borderWidth;
@property (nonatomic, assign) CGFloat cornerRadius;
@property (nonatomic, assign) CGFloat buttonHeight;
@property (nonatomic, strong) SelectionHandler selectionHandler;

+ (CNPPopupButtonItem *)defaultButtonItemWithTitle:(NSAttributedString *)title backgroundColor:(UIColor *)color;

@end

@interface CNPPopupTheme : NSObject

@property (nonatomic, strong) UIColor *backgroundColor; // Background color of the popup content view (Default white)
@property (nonatomic, assign) CGFloat cornerRadius; // Corner radius of the popup content view (Default 6.0)
@property (nonatomic, assign) UIEdgeInsets popupContentInsets; // Inset of labels, images and buttons on the popup content view (Default 16.0 on all sides)
@property (nonatomic, assign) CNPPopupStyle popupStyle; // How the popup looks once presented (Default centered)
@property (nonatomic, assign) CNPPopupPresentationStyle presentationStyle; // How the popup is presented (Defauly slide in from bottom)
@property (nonatomic, assign) BOOL dismissesOppositeDirection; // If presented from a direction, should it dismiss in the opposite? (Defaults to NO. i.e. Goes back the way it came in)
@property (nonatomic, assign) CNPPopupMaskType maskType; // Backgound mask of the popup (Default dimmed)
@property (nonatomic, assign) BOOL shouldDismissOnBackgroundTouch; // Popup should dismiss on tapping on background mask (Default yes)
@property (nonatomic, assign) CGFloat contentVerticalPadding; // Spacing between each vertical element (Default 12.0)

// Factory method to help build a default theme
+ (CNPPopupTheme *)defaultTheme;

@end
