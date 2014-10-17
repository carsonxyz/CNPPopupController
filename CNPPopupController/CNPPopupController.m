//
//  CNPPopupController.m
//  CNPPopupController
//
//  Created by Carson Perrotti on 2014-09-28.
//  Copyright (c) 2014 Carson Perrotti. All rights reserved.
//

#import "CNPPopupController.h"
#import <QuartzCore/QuartzCore.h>
#import <PureLayout.h>

#define CNP_IS_IPAD   (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)


typedef struct {
    CGFloat top;
    CGFloat bottom;
} CNPTopBottomPadding;

extern CNPTopBottomPadding CNPTopBottomPaddingMake(CGFloat top, CGFloat bottom) {
    CNPTopBottomPadding padding;
    padding.top = top;
    padding.bottom = bottom;
    return padding;
};

@interface CNPPopupController ()

@property (nonatomic, strong) UIView *maskView;
@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) UIWindow *applicationKeyWindow;
@property (nonatomic, assign) BOOL isShowing;

@property (nonatomic, strong) NSLayoutConstraint *contentViewCenterXConstraint;
@property (nonatomic, strong) NSLayoutConstraint *contentViewCenterYConstraint;
@property (nonatomic, strong) NSLayoutConstraint *contentViewWidth;
@property (nonatomic, strong) NSLayoutConstraint *contentViewHeight;
@property (nonatomic, strong) NSLayoutConstraint *contentViewBottom;

@end

@implementation CNPPopupController

- (instancetype)initWithTitle:(NSAttributedString *)popupTitle
                     contents:(NSArray *)contents
                 buttonTitles:(NSArray *)buttonTitles
       destructiveButtonTitle:(NSAttributedString *)destructiveButtonTitle {
    self = [super init];
    if (self) {
        _popupTitle = popupTitle;
        _contents = contents;
        _buttonTitles = buttonTitles;
        _destructiveButtonTitle = destructiveButtonTitle;
        
        // Safety Checks
        if (contents) {
            for (id object in contents) {
                NSAssert([object class] != [NSAttributedString class] || [object class] != [UIImage class],@"Contents can only be of NSAttributedString or UIImage class.");
            }
        }
        if (buttonTitles) {
            for (id object in buttonTitles) {
                NSAssert([object class] != [NSAttributedString class],@"Button titles can only be of NSAttributedString.");
            }
        }
        
        // Window setup
        NSEnumerator *frontToBackWindows = [[[UIApplication sharedApplication] windows] reverseObjectEnumerator];
        for (UIWindow *window in frontToBackWindows) {
            if (window.windowLevel == UIWindowLevelNormal) {
                self.applicationKeyWindow = window;
                break;
            }
        }
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(statusBarFrameOrOrientationChanged:) name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(statusBarFrameOrOrientationChanged:) name:UIApplicationDidChangeStatusBarFrameNotification object:nil];
    }
    return self;
}

#pragma mark - Touch Handling

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch * touch = [[event allTouches] anyObject];
    if (touch.view == self.maskView) {
        // Try to dismiss if backgroundTouch flag set.
        if (self.theme.shouldDismissOnBackgroundTouch) {
            [self dismissPopupControllerAnimated:YES];
        }
    }
}

- (void)setUpPopup {
    
    // Set up mask view
    self.maskView = [[UIView alloc] init];
    [self.maskView setTranslatesAutoresizingMaskIntoConstraints:NO];
    self.maskView.alpha = 0.0;
    
    [self.applicationKeyWindow addSubview:self.maskView];
    [self.applicationKeyWindow addConstraint:[NSLayoutConstraint constraintWithItem:self.maskView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.applicationKeyWindow attribute:NSLayoutAttributeTop multiplier:1.0 constant:0]];
    [self.applicationKeyWindow addConstraint:[NSLayoutConstraint constraintWithItem:self.maskView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.applicationKeyWindow attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0]];
    [self.applicationKeyWindow addConstraint:[NSLayoutConstraint constraintWithItem:self.maskView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.applicationKeyWindow attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0]];
    [self.applicationKeyWindow addConstraint:[NSLayoutConstraint constraintWithItem:self.maskView attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self.applicationKeyWindow attribute:NSLayoutAttributeRight multiplier:1.0 constant:0]];
    
    if (self.theme.popupStyle == CNPPopupStyleFullscreen) {
        self.maskView.backgroundColor = [UIColor whiteColor];
    }
    else {
        if (self.theme.maskType == CNPPopupMaskTypeDimmed) {
            self.maskView.backgroundColor = [UIColor colorWithWhite:0.0f alpha:0.5f];
        } else {
            self.maskView.backgroundColor = [UIColor clearColor];
        }
    }
    
    self.contentView = [[UIView alloc] init];
    [self.contentView setTranslatesAutoresizingMaskIntoConstraints:NO];
    self.contentView.clipsToBounds = YES; 
    self.contentView.backgroundColor = self.theme.backgroundColor;
    self.contentView.layer.cornerRadius = self.theme.popupStyle == CNPPopupStyleCentered ? self.theme.cornerRadius : 0.0f;
    [self.maskView addSubview:self.contentView];
    
    
    if (self.popupTitle) {
        UILabel *title = [self multilineLabelWithAttributedString:self.popupTitle];
        [self.contentView addSubview:title];
    }
    
    if (self.contents) {
        for (NSObject *content in self.contents) {
            if ([content isKindOfClass:[NSAttributedString class]]) {
                UILabel *label = [self multilineLabelWithAttributedString:(NSAttributedString *)content];
                [self.contentView addSubview:label];
            }
            else if ([content isKindOfClass:[UIImage class]]) {
                UIImageView *imageView = [self centeredImageViewForImage:(UIImage *)content];
                [imageView sizeToFit];
                [self.contentView addSubview:imageView];
                [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:imageView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationLessThanOrEqual toItem:imageView attribute:NSLayoutAttributeWidth multiplier:1.0 constant:0]];
            }
        }
    }
    
    if (self.buttonTitles) {
        for (NSAttributedString *string in self.buttonTitles) {
            UIButton *button = [self buttonWithAttributedTitle:string];
            [self.contentView addSubview:button];
        }
    }
    
    [self.contentView.subviews enumerateObjectsUsingBlock:^(UIView *view, NSUInteger idx, BOOL *stop) {
        if (idx == 0) {
            [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeTop multiplier:1.0 constant:self.theme.popupContentInsets.top]];
        }
        else {
            UIView *previousSubView = [self.contentView.subviews objectAtIndex:idx - 1];
            if (previousSubView) {
                [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:previousSubView attribute:NSLayoutAttributeBottom multiplier:1.0 constant:self.theme.contentVerticalPadding]];
            }
        }
        
        if (idx == self.contentView.subviews.count - 1) {
            [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeBottom multiplier:1.0 constant:-(self.theme.popupContentInsets.bottom + (self.destructiveButtonTitle ? self.theme.buttonHeight : 0.0f))]];
        }
        
        if ([view isKindOfClass:[UIButton class]]) {
            UIButton *button = (UIButton *)view;
            [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:self.theme.buttonHeight]];
            [button addTarget:self action:@selector(actionButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        }
        
        [view setContentHuggingPriority:UILayoutPriorityDefaultHigh forAxis:UILayoutConstraintAxisVertical];
        [view setContentHuggingPriority:UILayoutPriorityDefaultHigh forAxis:UILayoutConstraintAxisHorizontal];
        
        if ([view isKindOfClass:[UIImageView class]]) {
            [view setContentCompressionResistancePriority:UILayoutPriorityDefaultHigh forAxis:UILayoutConstraintAxisHorizontal];
            [view setContentCompressionResistancePriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisVertical];
        }
        else {
            [view setContentCompressionResistancePriority:UILayoutPriorityDefaultHigh forAxis:UILayoutConstraintAxisHorizontal];
            [view setContentCompressionResistancePriority:UILayoutPriorityDefaultHigh forAxis:UILayoutConstraintAxisVertical];
        }
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeLeft multiplier:1.0 constant:self.theme.popupContentInsets.left]];
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeRight multiplier:1.0 constant:-self.theme.popupContentInsets.right]];
    }];
    
    if (self.destructiveButtonTitle) {
        UIButton *destructiveButton = [self destructiveButtonWithAttributedTitle:self.destructiveButtonTitle];
        [destructiveButton setBackgroundColor:self.theme.destructiveButtonBackgroundColor];
        [self.contentView addSubview:destructiveButton];
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:destructiveButton attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:self.theme.buttonHeight]];
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:destructiveButton attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0]];
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:destructiveButton attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0]];
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:destructiveButton attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeRight multiplier:1.0 constant:0]];
        [destructiveButton addTarget:self action:@selector(actionButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    }
    
    [self.maskView addConstraint:[NSLayoutConstraint constraintWithItem:self.contentView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationLessThanOrEqual toItem:self.maskView attribute:NSLayoutAttributeHeight multiplier:1.0 constant:0]];
    [self.maskView addConstraint:[NSLayoutConstraint constraintWithItem:self.contentView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationLessThanOrEqual toItem:self.maskView attribute:NSLayoutAttributeWidth multiplier:1.0 constant:0]];
    
    if (self.theme.popupStyle == CNPPopupStyleFullscreen) {
        self.contentViewWidth = [NSLayoutConstraint constraintWithItem:self.contentView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:self.maskView attribute:NSLayoutAttributeWidth multiplier:CNP_IS_IPAD?0.5:1.0 constant:0];
        [self.maskView addConstraint:self.contentViewWidth];
        self.contentViewCenterYConstraint = [NSLayoutConstraint constraintWithItem:self.contentView attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self.maskView attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0];
        [self.maskView addConstraint:self.contentViewCenterYConstraint];
        self.contentViewCenterXConstraint = [NSLayoutConstraint constraintWithItem:self.contentView attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self.maskView attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0];
        [self.maskView addConstraint:self.contentViewCenterXConstraint];
    }
    else if (self.theme.popupStyle == CNPPopupStyleActionSheet) {
        self.contentViewHeight = [NSLayoutConstraint constraintWithItem:self.contentView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:self.maskView attribute:NSLayoutAttributeWidth multiplier:CNP_IS_IPAD?0.5:1.0 constant:0];
        [self.maskView addConstraint:self.contentViewHeight];
        self.contentViewBottom = [NSLayoutConstraint constraintWithItem:self.contentView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.maskView attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0];
        [self.maskView addConstraint:self.contentViewBottom];
        self.contentViewCenterXConstraint = [NSLayoutConstraint constraintWithItem:self.contentView attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self.maskView attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0];
        [self.maskView addConstraint:self.contentViewCenterXConstraint];
    }
    else {
        if (CNP_IS_IPAD) {
            self.contentViewWidth = [NSLayoutConstraint constraintWithItem:self.contentView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:self.maskView attribute:NSLayoutAttributeWidth multiplier:0.4 constant:0];
        }
        else {
            self.contentViewWidth = [NSLayoutConstraint constraintWithItem:self.contentView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:self.maskView attribute:NSLayoutAttributeWidth multiplier:1.0 constant:-40];
        }
        [self.maskView addConstraint:self.contentViewWidth];
        self.contentViewCenterYConstraint = [NSLayoutConstraint constraintWithItem:self.contentView attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self.maskView attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0];
        [self.maskView addConstraint:self.contentViewCenterYConstraint];
        self.contentViewCenterXConstraint = [NSLayoutConstraint constraintWithItem:self.contentView attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self.maskView attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0];
        [self.maskView addConstraint:self.contentViewCenterXConstraint];
    }
    
}

- (void)actionButtonPressed:(UIButton *)sender {
    [self dismissPopupControllerAnimated:YES withButtonTitle:[sender attributedTitleForState:UIControlStateNormal].string];
}

#pragma mark - Presentation

- (void)presentPopupControllerAnimated:(BOOL)flag {
    
    
    // Safety Checks
    NSAssert(self.theme!=nil,@"You must set a theme. You can use [CNPTheme defaultTheme] as a starting place");
    
    [self rotateAccordingToStatusBarOrientationAndSupportedOrientations];
    
    [self setUpPopup];
    [self setOriginConstraints];
    [self.maskView needsUpdateConstraints];
    [self.maskView layoutIfNeeded];
    [self setPresentedConstraints];
    
    if ([self.delegate respondsToSelector:@selector(popupControllerWillPresent:)]) {
        [self.delegate popupControllerWillPresent:self];
    }
    
    [UIView animateWithDuration:flag ? 0.3f : 0.0f
                          delay:0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         self.maskView.alpha = 1.0f;
                         [self.maskView needsUpdateConstraints];
                         [self.maskView layoutIfNeeded];
                     }
                     completion:^(BOOL finished) {
                         self.isShowing = YES;
                         if ([self.delegate respondsToSelector:@selector(popupControllerDidPresent:)]) {
                             [self.delegate popupControllerDidPresent:self];
                         }
                     }];
}

- (void)dismissPopupControllerAnimated:(BOOL)flag {
    [self dismissPopupControllerAnimated:flag withButtonTitle:nil];
}

- (void)dismissPopupControllerAnimated:(BOOL)flag withButtonTitle:(NSString *)title {

    if (self.theme.dismissesOppositeDirection) {
        [self setDismissedConstraints];
    } else {
        [self setOriginConstraints];
    }
    
    if ([self.delegate respondsToSelector:@selector(popupController:willDismissWithButtonTitle:)]) {
        [self.delegate popupController:self willDismissWithButtonTitle:title];
    }
    
    [UIView animateWithDuration:flag ? 0.3f : 0.0f
                          delay:0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         self.maskView.alpha = 0.0f;
                         [self.maskView needsUpdateConstraints];
                         [self.maskView layoutIfNeeded];
                     }
                     completion:^(BOOL finished) {
                         [self.maskView removeFromSuperview];
                         self.maskView = nil;
                         self.contentView = nil;
                         self.isShowing = NO;
                         if ([self.delegate respondsToSelector:@selector(popupController:didDismissWithButtonTitle:)]) {
                             [self.delegate popupController:self didDismissWithButtonTitle:title];
                         }
                     }];
}

- (void)setOriginConstraints {

    if (self.theme.popupStyle == CNPPopupStyleCentered) {
        switch (self.theme.presentationStyle) {
            case CNPPopupPresentationStyleFadeIn:
                self.contentViewCenterYConstraint.constant = 0;
                self.contentViewCenterXConstraint.constant = 0;
                break;
            case CNPPopupPresentationStyleSlideInFromTop:
                self.contentViewCenterYConstraint.constant = -self.applicationKeyWindow.bounds.size.height;
                self.contentViewCenterXConstraint.constant = 0;
                break;
            case CNPPopupPresentationStyleSlideInFromBottom:
                self.contentViewCenterYConstraint.constant = self.applicationKeyWindow.bounds.size.height;
                self.contentViewCenterXConstraint.constant = 0;
                break;
            case CNPPopupPresentationStyleSlideInFromLeft:
                self.contentViewCenterYConstraint.constant = 0;
                self.contentViewCenterXConstraint.constant = -self.applicationKeyWindow.bounds.size.height;
                break;
            case CNPPopupPresentationStyleSlideInFromRight:
                self.contentViewCenterYConstraint.constant = 0;
                self.contentViewCenterXConstraint.constant = self.applicationKeyWindow.bounds.size.height;
                break;
            default:
                self.contentViewCenterYConstraint.constant = 0;
                self.contentViewCenterXConstraint.constant = 0;
                break;
        }
    }
    else if (self.theme.popupStyle == CNPPopupStyleActionSheet) {
        self.contentViewBottom.constant = self.applicationKeyWindow.bounds.size.height;
    }
}

- (void)setDismissedConstraints {
    
    if (self.theme.popupStyle == CNPPopupStyleCentered) {
        switch (self.theme.presentationStyle) {
            case CNPPopupPresentationStyleFadeIn:
                self.contentViewCenterYConstraint.constant = 0;
                self.contentViewCenterXConstraint.constant = 0;
                break;
            case CNPPopupPresentationStyleSlideInFromTop:
                self.contentViewCenterYConstraint.constant = self.applicationKeyWindow.bounds.size.height;
                self.contentViewCenterXConstraint.constant = 0;
                break;
            case CNPPopupPresentationStyleSlideInFromBottom:
                self.contentViewCenterYConstraint.constant = -self.applicationKeyWindow.bounds.size.height;
                self.contentViewCenterXConstraint.constant = 0;
                break;
            case CNPPopupPresentationStyleSlideInFromLeft:
                self.contentViewCenterYConstraint.constant = 0;
                self.contentViewCenterXConstraint.constant = self.applicationKeyWindow.bounds.size.height;
                break;
            case CNPPopupPresentationStyleSlideInFromRight:
                self.contentViewCenterYConstraint.constant = 0;
                self.contentViewCenterXConstraint.constant = -self.applicationKeyWindow.bounds.size.height;
                break;
            default:
                self.contentViewCenterYConstraint.constant = 0;
                self.contentViewCenterXConstraint.constant = 0;
                break;
        }
    }
    else if (self.theme.popupStyle == CNPPopupStyleActionSheet) {
        self.contentViewBottom.constant = self.applicationKeyWindow.bounds.size.height;
    }
}

- (void)setPresentedConstraints {
    
    if (self.theme.popupStyle == CNPPopupStyleCentered) {
        self.contentViewCenterYConstraint.constant = 0;
        self.contentViewCenterXConstraint.constant = 0;
    }
    else if (self.theme.popupStyle == CNPPopupStyleActionSheet) {
        self.contentViewBottom.constant = 0;
    }
}

#pragma mark - Window Handling

- (void)statusBarFrameOrOrientationChanged:(NSNotification *)notification
{
    [self rotateAccordingToStatusBarOrientationAndSupportedOrientations];
}

- (void)rotateAccordingToStatusBarOrientationAndSupportedOrientations
{
    UIInterfaceOrientation statusBarOrientation = [UIApplication sharedApplication].statusBarOrientation;
    CGFloat angle = UIInterfaceOrientationAngleOfOrientation(statusBarOrientation);
    CGFloat statusBarHeight = [self getStatusBarHeight];
    
    CGAffineTransform transform = CGAffineTransformMakeRotation(angle);
    CGRect frame = [self rectInWindowBounds:self.applicationKeyWindow.bounds statusBarOrientation:statusBarOrientation statusBarHeight:statusBarHeight];
    
    [self setIfNotEqualTransform:transform frame:frame];
}

- (void)setIfNotEqualTransform:(CGAffineTransform)transform frame:(CGRect)frame
{
    if(!CGAffineTransformEqualToTransform(self.maskView.transform, transform))
    {
        self.maskView.transform = transform;
    }
    if(!CGRectEqualToRect(self.maskView.frame, frame))
    {
        self.maskView.frame = frame;
    }
}

- (CGFloat)getStatusBarHeight
{
    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
    if(UIInterfaceOrientationIsLandscape(orientation))
    {
        return [UIApplication sharedApplication].statusBarFrame.size.width;
    }
    else
    {
        return [UIApplication sharedApplication].statusBarFrame.size.height;
    }
}

- (CGRect)rectInWindowBounds:(CGRect)windowBounds statusBarOrientation:(UIInterfaceOrientation)statusBarOrientation statusBarHeight:(CGFloat)statusBarHeight
{
    CGRect frame = windowBounds;
    frame.origin.x += statusBarOrientation == UIInterfaceOrientationLandscapeLeft ? statusBarHeight : 0;
    frame.origin.y += statusBarOrientation == UIInterfaceOrientationPortrait ? statusBarHeight : 0;
    frame.size.width -= UIInterfaceOrientationIsLandscape(statusBarOrientation) ? statusBarHeight : 0;
    frame.size.height -= UIInterfaceOrientationIsPortrait(statusBarOrientation) ? statusBarHeight : 0;
    return frame;
}

CGFloat UIInterfaceOrientationAngleOfOrientation(UIInterfaceOrientation orientation)
{
    CGFloat angle;
    
    switch (orientation)
    {
        case UIInterfaceOrientationPortraitUpsideDown:
            angle = M_PI;
            break;
        case UIInterfaceOrientationLandscapeLeft:
            angle = -M_PI_2;
            break;
        case UIInterfaceOrientationLandscapeRight:
            angle = M_PI_2;
            break;
        default:
            angle = 0.0;
            break;
    }
    
    return angle;
}

UIInterfaceOrientationMask UIInterfaceOrientationMaskFromOrientation(UIInterfaceOrientation orientation)
{
    return 1 << orientation;
}

#pragma mark - Factories 

- (UILabel *)multilineLabelWithAttributedString:(NSAttributedString *)attributedString {
    UILabel *label = [[UILabel alloc] init];
    [label setTranslatesAutoresizingMaskIntoConstraints:NO];
    [label setAttributedText:attributedString];
    [label setNumberOfLines:0];
    return label;
}

- (UIImageView *)centeredImageViewForImage:(UIImage *)image {
    UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
    [imageView setTranslatesAutoresizingMaskIntoConstraints:NO];
    [imageView setContentMode:UIViewContentModeScaleAspectFit];
    return imageView;
}

- (UIButton *)buttonWithAttributedTitle:(NSAttributedString *)attributedTitle {
    UIButton *button = [[UIButton alloc] init];
    [button setTranslatesAutoresizingMaskIntoConstraints:NO];
    [button setAttributedTitle:attributedTitle forState:UIControlStateNormal];
    [button setBackgroundColor:self.theme.buttonBackgroundColor];
    [button.layer setCornerRadius:self.theme.buttonCornerRadius];
    return button;
}

- (UIButton *)destructiveButtonWithAttributedTitle:(NSAttributedString *)attributedTitle {
    UIButton *button = [[UIButton alloc] init];
    [button setTranslatesAutoresizingMaskIntoConstraints:NO];
    [button setAttributedTitle:attributedTitle forState:UIControlStateNormal];
    [button setBackgroundColor:self.theme.destructiveButtonBackgroundColor];
    return button;
}

@end
