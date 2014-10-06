//
//  CNPPopupTheme.h
//  CNPPopupControllerExample
//
//  Created by Carson Perrotti on 2014-09-28.
//  Copyright (c) 2014 Carson Perrotti. All rights reserved.
//

#import <UIKit/UIKit.h>

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

@interface CNPPopupTheme : NSObject

@property (nonatomic, strong) UIColor *backgroundColor; // Background color of the popup content view (Default white)
@property (nonatomic, assign) CGFloat cornerRadius; // Corner radius of the popup content view (Default 6.0)
@property (nonatomic, strong) UIColor *buttonBackgroundColor; // Background color of the content buttons (Default gray)
@property (nonatomic, strong) UIColor *destructiveButtonBackgroundColor; // Background color of the destructive button at the bottom of the popup (Default light gray)
@property (nonatomic, assign) CGFloat buttonHeight; // Height of the action buttons (Default 44.0f)
@property (nonatomic, assign) CGFloat buttonCornerRadius; // Corner radius of the action buttons (Default 6.0f)
@property (nonatomic, assign) UIEdgeInsets popupContentInsets; // Inset of labels, images and buttons on the popup content view (Default 16.0 on all sides)
@property (nonatomic, assign) CNPPopupStyle popupStyle; // How the popup looks once presented (Default centered)
@property (nonatomic, assign) CNPPopupPresentationStyle presentationStyle; // How the popup is presented (Defauly slide in from bottom)
@property (nonatomic, assign) CNPPopupMaskType maskType; // Backgound mask of the popup (Default dimmed)
@property (nonatomic, assign) BOOL shouldDismissOnBackgroundTouch; // Popup should dismiss on tapping on background mask (Default yes)
@property (nonatomic, assign) CGFloat contentVerticalPadding; // Spacing between each vertical element (Default 12.0)

// Factory method to help build a default theme
+ (CNPPopupTheme *)defaultTheme;

@end
