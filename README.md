#CNPPopupController
[![Pod Version](http://img.shields.io/cocoapods/v/CNPPopupController.svg?style=flat)](http://cocoadocs.org/docsets/CNPPopupController/)
[![Pod Platform](http://img.shields.io/cocoapods/p/CNPPopupController.svg?style=flat)](http://cocoadocs.org/docsets/CNPPopupController/)
[![Pod License](http://img.shields.io/cocoapods/l/CNPPopupController.svg?style=flat)](https://github.com/carsonperrotti/CNPPopupController/blob/master/LICENSE)
[![Dependency Status](https://www.versioneye.com/objective-c/cnppopupcontroller/0.2.1/badge.svg?style=flat)](https://www.versioneye.com/objective-c/cnppopupcontroller)

##Introduction

CNPPopupController is a simple and versatile class for presenting a custom popup in a variety of fashions. It includes a many options for controlling how your popup appears and behaves.

Please feel free to contribute to this project, open issues, make suggestions and submit pull-requests. If you use this project in your app, let me know. I'd love to see what you do with it.

<p align="center"><img src="https://raw.githubusercontent.com/carsonperrotti/CNPPopupController/master/CNPPopupControllerExample/CNPPopupController.gif"/></p>

## Installation

Available in [CocoaPods](http://cocoapods.org/?q=CNPPopupController)

`pod 'CNPPopupController'`

##Usage

(See sample Xcode project in `/CNPPopupControllerExample`)

## Creating a Popup

Create a popup with custom animations and behaviors. Customizations can also be accessed via properties on the `CNPPopupTheme` instance:

	- (instancetype)initWithContents:(NSArray *)contents;


`contents` only accepts an array of `UIView` objects.

## Presentation

`- (void)presentPopupControllerAnimated:(BOOL)flag;`

`- (void)dismissPopupControllerAnimated:(BOOL)flag;`

## Customization

A `CNPPopupTheme` instance can be created and assigned to the `theme` property of a `CNPPopupController` instance.

`@property (nonatomic, strong) UIColor *backgroundColor;`

`@property (nonatomic, assign) CGFloat cornerRadius;`

`@property (nonatomic, assign) UIEdgeInsets popupContentInsets;`

`@property (nonatomic, assign) CNPPopupStyle popupStyle;`

`@property (nonatomic, assign) CNPPopupPresentationStyle presentationStyle;`

`@property (nonatomic, assign) CNPPopupMaskType maskType;`

`@property (nonatomic, assign) BOOL dismissesOppositeDirection;`

`@property (nonatomic, assign) BOOL shouldDismissOnBackgroundTouch;`

`@property (nonatomic, assign) BOOL movesAboveKeyboard;`

`@property (nonatomic, assign) CGFloat contentVerticalPadding;`

`@property (nonatomic, assign) CGFloat maxPopupWidth;`

`@property (nonatomic, assign) CGFloat animationDuration;`

## Notes

### Deployment
`CNPPopupController ` works on **iOS 6 - iOS 10**

##Credits
CNPPopupController was created by [Carson Perrotti](http://carsonperrotti.com)

##Version History

**September 15, 2016 v0.3.3**
- Content layout fixes
- Better swift support

**July 14, 2016 v0.3.2**
- Fixes an issue where content would not be perfectly centred.
- Project compatibility fixes to prevent `duplicate symbols` errors.
- Added property to adjust animation transition duration.

**September 13, 2015 v0.3.1**
- Sets `movesAboveKeyboard` to `YES` in the default theme.

**September 11, 2015 v0.3.0**
- Support for iOS 9 and a few bug fixes.

**August 30, 2015 v0.2.3**
- Lower minimum required OS version to 6.0, since it works there anyway.

**August 16, 2015 v0.2.2**
- Bug fix for centering the popup above the keyboard when presented. Thanks to [Nicholas](https://github.com/nicholas) for the proactive help on this one.

**June 14th, 2015 v0.2.0**
- Completely rewritten. *Started from the bottom, now we're here.*
- There are some minor API changes in v0.2.0. I tried to keep it as close to the last version as possible. See the example project if you need some help getting it set up.
- Custom view support (You can add anything, as it's contents as long as it is a UIView or subclass of UIView
- Lots of bug fixes
