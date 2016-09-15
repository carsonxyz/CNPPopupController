//
//  CNPPopupController.m
//  CNPPopupController
//
//  Created by Carson Perrotti on 2014-09-28.
//  Copyright (c) 2014 Carson Perrotti. All rights reserved.
//

#import "CNPPopupController.h"

#define CNP_SYSTEM_VERSION_LESS_THAN(v) ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)
#define CNP_IS_IPAD   (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)

static inline UIViewAnimationOptions UIViewAnimationCurveToAnimationOptions(UIViewAnimationCurve curve)
{
    return curve << 16;
}

@interface CNPPopupController () <UIGestureRecognizerDelegate>

@property (nonatomic, strong) UIWindow *applicationWindow;
@property (nonatomic, strong) UIView *maskView;
@property (nonatomic, strong) UITapGestureRecognizer *backgroundTapRecognizer;
@property (nonatomic, strong) UIView *popupView;
@property (nonatomic, strong) NSArray <UIView *> *views;
@property (nonatomic) BOOL dismissAnimated;

@end

@implementation CNPPopupController


- (instancetype)initWithContents:(NSArray <UIView *> *)contents {
    self = [super init];
    if (self) {
        
        self.views = contents;
        
        self.popupView = [[UIView alloc] initWithFrame:CGRectZero];
        self.popupView.backgroundColor = [UIColor whiteColor];
        self.popupView.clipsToBounds = YES;
        
        self.maskView = [[UIView alloc] initWithFrame:self.applicationWindow.bounds];
        self.maskView.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.7];
        self.backgroundTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleBackgroundTapGesture:)];
        self.backgroundTapRecognizer.delegate = self;
        [self.maskView addGestureRecognizer:self.backgroundTapRecognizer];
        [self.maskView addSubview:self.popupView];
        
        self.theme = [CNPPopupTheme defaultTheme];

        [self addPopupContents];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
        
        [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(orientationWillChange)
                                                     name:UIApplicationWillChangeStatusBarOrientationNotification
                                                   object:nil];
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(orientationChanged)
                                                     name:UIApplicationDidChangeStatusBarOrientationNotification
                                                   object:nil];
    }
    return self;
}

- (instancetype)init {
    self = [self initWithContents:@[]];
    return self;
}

- (void)dealloc {
    [[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
    [[NSNotificationCenter defaultCenter]removeObserver:self name:UIApplicationWillChangeStatusBarOrientationNotification object:nil];
    [[NSNotificationCenter defaultCenter]removeObserver:self name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];
    [[NSNotificationCenter defaultCenter]removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter]removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

- (void)orientationWillChange {
    
    [UIView animateWithDuration:self.theme.animationDuration animations:^{
        self.maskView.frame = self.applicationWindow.bounds;
        self.popupView.center = [self endingPoint];
    }];
}

- (void)orientationChanged {
    
    UIInterfaceOrientation statusBarOrientation = [UIApplication sharedApplication].statusBarOrientation;
    CGFloat angle = CNP_UIInterfaceOrientationAngleOfOrientation(statusBarOrientation);
    CGAffineTransform transform = CGAffineTransformMakeRotation(angle);
    
    [UIView animateWithDuration:self.theme.animationDuration animations:^{
        self.maskView.frame = self.applicationWindow.bounds;
        self.popupView.center = [self endingPoint];
        if (CNP_SYSTEM_VERSION_LESS_THAN(@"8.0")) {
            self.popupView.transform = transform;
        }
    }];
}

CGFloat CNP_UIInterfaceOrientationAngleOfOrientation(UIInterfaceOrientation orientation)
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


#pragma mark - Theming

- (void)applyTheme {
    if (self.theme.popupStyle == CNPPopupStyleFullscreen) {
        self.theme.presentationStyle = CNPPopupPresentationStyleFadeIn;
    }
    if (self.theme.popupStyle == CNPPopupStyleActionSheet) {
        self.theme.presentationStyle = CNPPopupPresentationStyleSlideInFromBottom;
    }
    self.popupView.layer.cornerRadius = self.theme.popupStyle == CNPPopupStyleCentered?self.theme.cornerRadius:0;
    self.popupView.backgroundColor = self.theme.backgroundColor;
    UIColor *maskBackgroundColor;
    if (self.theme.popupStyle == CNPPopupStyleFullscreen) {
        maskBackgroundColor = self.popupView.backgroundColor;
    }
    else {
        maskBackgroundColor = self.theme.maskType == CNPPopupMaskTypeClear?[UIColor clearColor] : [UIColor colorWithWhite:0.0 alpha:0.7];
    }
    self.maskView.backgroundColor = maskBackgroundColor;
}

#pragma mark - Popup Building

- (void)addPopupContents {
    for (UIView *view in self.views)
    {
        [self.popupView addSubview:view];
    }
}

- (CGSize)calculateContentSizeThatFits:(CGSize)size andUpdateLayout:(BOOL)update
{
    UIEdgeInsets inset = self.theme.popupContentInsets;
    size.width -= (inset.left + inset.right);
    size.height -= (inset.top + inset.bottom);
    
    CGSize result = CGSizeMake(0, inset.top);
    for (UIView *view in self.popupView.subviews)
    {
        view.autoresizingMask = UIViewAutoresizingNone;
        if (!view.hidden)
        {
            CGSize _size = view.frame.size;
            if (CGSizeEqualToSize(_size, CGSizeZero))
            {
                _size = [view sizeThatFits:size];
                _size.width = size.width;
                if (update) view.frame = CGRectMake(inset.left, result.height, _size.width, _size.height);
            }
            else {
                if (update) {
                    view.frame = CGRectMake(0, result.height, _size.width, _size.height);
                }
            }
            result.height += _size.height + self.theme.contentVerticalPadding;
            result.width = MAX(result.width, _size.width);
        }
    }
    
    result.height -= self.theme.contentVerticalPadding;
    result.width += inset.left + inset.right;
    result.height = MIN(INFINITY, MAX(0.0f, result.height + inset.bottom));
    if (update) {
        for (UIView *view in self.popupView.subviews) {
            view.frame = CGRectMake((result.width - view.frame.size.width) * 0.5, view.frame.origin.y, view.frame.size.width, view.frame.size.height);
        }
        self.popupView.frame = CGRectMake(0, 0, result.width, result.height);
    }
    return result;
}

- (CGSize)sizeThatFits:(CGSize)size
{
    return [self calculateContentSizeThatFits:size andUpdateLayout:NO];
}

#pragma mark - Keyboard 

- (void)keyboardWillShow:(NSNotification*)notification
{
    if (self.theme.movesAboveKeyboard) {
        CGRect frame = [notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
        frame = [self.popupView convertRect:frame fromView:nil];
        NSTimeInterval duration = [(notification.userInfo)[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
        UIViewAnimationCurve curve = [(notification.userInfo)[UIKeyboardAnimationCurveUserInfoKey] integerValue];
        
        [self keyboardWithEndFrame:frame willShowAfterDuration:duration withOptions:UIViewAnimationCurveToAnimationOptions(curve)];
    }
}

- (void)keyboardWithEndFrame:(CGRect)keyboardFrame willShowAfterDuration:(NSTimeInterval)duration withOptions:(UIViewAnimationOptions)options
{
    CGRect popupViewIntersection = CGRectIntersection(self.popupView.frame, keyboardFrame);
    
    if (popupViewIntersection.size.height > 0) {
        CGRect maskViewIntersection = CGRectIntersection(self.maskView.frame, keyboardFrame);
        
        [UIView animateWithDuration:duration delay:0.0f options:options animations:^{
            self.popupView.center = CGPointMake(self.popupView.center.x, (CGRectGetHeight(self.maskView.frame) - maskViewIntersection.size.height) / 2);
        } completion:nil];
    }
}

- (void)keyboardWillHide:(NSNotification*)notification
{
    if (self.theme.movesAboveKeyboard) {
        CGRect frame = [notification.userInfo[UIKeyboardFrameBeginUserInfoKey] CGRectValue];
        frame = [self.popupView convertRect:frame fromView:nil];
        NSTimeInterval duration = [(notification.userInfo)[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
        UIViewAnimationCurve curve = [(notification.userInfo)[UIKeyboardAnimationCurveUserInfoKey] integerValue];
        
        [self keyboardWithStartFrame:frame willHideAfterDuration:duration withOptions:UIViewAnimationCurveToAnimationOptions(curve)];
    }
}

- (void)keyboardWithStartFrame:(CGRect)keyboardFrame willHideAfterDuration:(NSTimeInterval)duration withOptions:(UIViewAnimationOptions)options
{
    [UIView animateWithDuration:duration delay:0.0f options:options animations:^{
        self.popupView.center = [self endingPoint];
    } completion:nil];
}

#pragma mark - Presentation

- (void)presentPopupControllerAnimated:(BOOL)flag {
    
    if ([self.delegate respondsToSelector:@selector(popupControllerWillPresent:)]) {
        [self.delegate popupControllerWillPresent:self];
    }
    
    // Keep a record of if the popup was presented with animation
    self.dismissAnimated = flag;
    
    [self applyTheme];
    [self calculateContentSizeThatFits:CGSizeMake([self popupWidth], self.maskView.bounds.size.height) andUpdateLayout:YES];
    self.popupView.center = [self originPoint];
    [self.applicationWindow addSubview:self.maskView];
    self.maskView.alpha = 0;
    [UIView animateWithDuration:flag?self.theme.animationDuration:0.0 animations:^{
        self.maskView.alpha = 1.0;
        self.popupView.center = [self endingPoint];;
    } completion:^(BOOL finished) {
        self.popupView.userInteractionEnabled = YES;
        if ([self.delegate respondsToSelector:@selector(popupControllerDidPresent:)]) {
            [self.delegate popupControllerDidPresent:self];
        }
    }];
}

- (void)dismissPopupControllerAnimated:(BOOL)flag {
    if ([self.delegate respondsToSelector:@selector(popupControllerWillDismiss:)]) {
        [self.delegate popupControllerWillDismiss:self];
    }
    [UIView animateWithDuration:flag?self.theme.animationDuration:0.0 animations:^{
        self.maskView.alpha = 0.0;
        self.popupView.center = [self dismissedPoint];;
    } completion:^(BOOL finished) {
        [self.maskView removeFromSuperview];
        if ([self.delegate respondsToSelector:@selector(popupControllerDidDismiss:)]) {
            [self.delegate popupControllerDidDismiss:self];
        }
    }];
}

- (CGPoint)originPoint {
    CGPoint origin;
    switch (self.theme.presentationStyle) {
        case CNPPopupPresentationStyleFadeIn:
            origin = self.maskView.center;
            break;
        case CNPPopupPresentationStyleSlideInFromBottom:
            origin = CGPointMake(self.maskView.center.x, self.maskView.bounds.size.height + self.popupView.bounds.size.height);
            break;
        case CNPPopupPresentationStyleSlideInFromLeft:
            origin = CGPointMake(-self.popupView.bounds.size.width, self.maskView.center.y);
            break;
        case CNPPopupPresentationStyleSlideInFromRight:
            origin = CGPointMake(self.maskView.bounds.size.width+self.popupView.bounds.size.width, self.maskView.center.y);
            break;
        case CNPPopupPresentationStyleSlideInFromTop:
            origin = CGPointMake(self.maskView.center.x, -self.popupView.bounds.size.height);
            break;
        default:
            origin = self.maskView.center;
            break;
    }
    return origin;
}

- (CGPoint)endingPoint {
    CGPoint center;
    if (self.theme.popupStyle == CNPPopupStyleActionSheet) {
        center = CGPointMake(self.maskView.center.x, self.maskView.bounds.size.height-(self.popupView.bounds.size.height * 0.5));
    }
    else {
        center = self.maskView.center;
    }
    return center;
}

- (CGPoint)dismissedPoint {
    CGPoint dismissed;
    switch (self.theme.presentationStyle) {
        case CNPPopupPresentationStyleFadeIn:
            dismissed = self.maskView.center;
            break;
        case CNPPopupPresentationStyleSlideInFromBottom:
            dismissed = self.theme.dismissesOppositeDirection?CGPointMake(self.maskView.center.x, -self.popupView.bounds.size.height):CGPointMake(self.maskView.center.x, self.maskView.bounds.size.height + self.popupView.bounds.size.height);
            if (self.theme.popupStyle == CNPPopupStyleActionSheet) {
                dismissed = CGPointMake(self.maskView.center.x, self.maskView.bounds.size.height + self.popupView.bounds.size.height);
            }
            break;
        case CNPPopupPresentationStyleSlideInFromLeft:
            dismissed = self.theme.dismissesOppositeDirection?CGPointMake(self.maskView.bounds.size.width+self.popupView.bounds.size.width, self.maskView.center.y):CGPointMake(-self.popupView.bounds.size.width, self.maskView.center.y);
            break;
        case CNPPopupPresentationStyleSlideInFromRight:
            dismissed = self.theme.dismissesOppositeDirection?CGPointMake(-self.popupView.bounds.size.width, self.maskView.center.y):CGPointMake(self.maskView.bounds.size.width+self.popupView.bounds.size.width, self.maskView.center.y);
            break;
        case CNPPopupPresentationStyleSlideInFromTop:
            dismissed = self.theme.dismissesOppositeDirection?CGPointMake(self.maskView.center.x, self.maskView.bounds.size.height + self.popupView.bounds.size.height):CGPointMake(self.maskView.center.x, -self.popupView.bounds.size.height);
            break;
        default:
            dismissed = self.maskView.center;
            break;
    }
    return dismissed;
}

- (CGFloat)popupWidth {
    CGFloat width = self.theme.maxPopupWidth;
    if ((self.theme.popupStyle == CNPPopupStyleActionSheet && !CNP_IS_IPAD ) || self.theme.popupStyle == CNPPopupStyleFullscreen) {
        width = self.maskView.bounds.size.width;
    }
    return width;
}

#pragma mark - UIGestureRecognizerDelegate 

- (void)handleBackgroundTapGesture:(id)sender {
    if (self.theme.shouldDismissOnBackgroundTouch) {
        [self.popupView endEditing:YES];
        [self dismissPopupControllerAnimated:self.dismissAnimated];
    }
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    if ([touch.view isDescendantOfView:self.popupView])
        return NO;
    return YES;
}

- (UIWindow *)applicationWindow {
    return [UIApplication sharedApplication].keyWindow;
}

@end

#pragma mark - CNPPopupButton Methods

@implementation CNPPopupButton

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self addTarget:self action:@selector(buttonTouched) forControlEvents:UIControlEventTouchUpInside];
    }
    return self;
}

- (void)buttonTouched {
    if (self.selectionHandler) {
        self.selectionHandler(self);
    }
}

@end

#pragma mark - CNPPopupTheme Methods

@implementation CNPPopupTheme

+ (CNPPopupTheme *)defaultTheme {
    CNPPopupTheme *defaultTheme = [[CNPPopupTheme alloc] init];
    defaultTheme.backgroundColor = [UIColor whiteColor];
    defaultTheme.cornerRadius = 4.0f;
    defaultTheme.popupContentInsets = UIEdgeInsetsMake(16.0f, 16.0f, 16.0f, 16.0f);
    defaultTheme.popupStyle = CNPPopupStyleCentered;
    defaultTheme.presentationStyle = CNPPopupPresentationStyleSlideInFromBottom;
    defaultTheme.dismissesOppositeDirection = NO;
    defaultTheme.maskType = CNPPopupMaskTypeDimmed;
    defaultTheme.shouldDismissOnBackgroundTouch = YES;
    defaultTheme.movesAboveKeyboard = YES;
    defaultTheme.contentVerticalPadding = 16.0f;
    defaultTheme.maxPopupWidth = 300.0f;
    defaultTheme.animationDuration = 0.3f;
    return defaultTheme;
}

@end
