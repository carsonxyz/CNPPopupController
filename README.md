#CNPPopupController

##Version History
**June 24th, 2015 v0.2.1**
- Bug fix for dismissing on background mask touch.

**June 14th, 2015 v0.2.0**
- Completely rewritten. *Started from the bottom, now we're here.*
- Ther are some minor API changes in v0.2.0. I tried to keep it as close to the last version as possible. See the example project if you need some help getting it set up.
- Custom view support (You can add anything, as it's contents as long as it is a UIView or subclass of UIView
- Lots of bug fixes

##Introduction

CNPPopupController is a simple and versatile class for presenting a custom popup in a variety of fashions. It includes a many options for controlling how your popup appears and behaves.

Please feel free to contribute to this project, open issues, make suggestions and submit pull-requests. If you use this project in your app, let me know. I'd love to see what you do with it. 

<p align="center"><img src="https://raw.githubusercontent.com/carsonperrotti/CNPPopupController/master/CNPPopupControllerExample/CNPPopupController.gif"/></p>

## Installation

Available in [Cocoa Pods](http://cocoapods.org/?q=CNPPopupController)

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

## Notes

### Deployment
`CNPPopupController ` works on **iOS 7** and **iOS 8**.

##Credits
CNPPopupController was created by [Carson Perrotti](http://carsonperrotti.com)
