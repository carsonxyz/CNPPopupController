//
//  CNPPopupController.m
//  CNPPopupController
//
//  Created by Carson Perrotti on 2014-09-28.
//  Copyright (c) 2014 Carson Perrotti. All rights reserved.
//

#import "CNPPopupController.h"
#import <QuartzCore/QuartzCore.h>

#define SYSTEM_VERSION_LESS_THAN_OR_EQUAL_TO(v)     ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedDescending)

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

@property (nonatomic, strong)   UIView *maskView;
@property (nonatomic, strong)   UIView *contentView;
@property (nonatomic, weak)     UIWindow *applicationKeyWindow;
@property (nonatomic, assign)   BOOL isShowing;

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
        // register for notifications
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(didChangeStatusBarOrientation:)
                                                     name:UIApplicationDidChangeStatusBarFrameNotification
                                                   object:nil];
        self.theme = [CNPPopupTheme defaultTheme];
    }
    return self;
}

- (void)dealloc {
    // Stop listening to notifications
    [[NSNotificationCenter defaultCenter] removeObserver:self];
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


#pragma mark - Orientation Handling

- (void)updateForInterfaceOrientation {
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    CGFloat angle;
    switch (orientation) {
        case UIInterfaceOrientationPortraitUpsideDown:
            angle = M_PI;
            break;
        case UIInterfaceOrientationLandscapeLeft:
            angle = -M_PI/2.0f;;
            break;
        case UIInterfaceOrientationLandscapeRight:
            angle = M_PI/2.0f;
            break;
        default: // as UIInterfaceOrientationPortrait
            angle = 0.0;
            break;
    }
    self.transform = CGAffineTransformMakeRotation(angle);
    self.frame = self.window.bounds;
    self.maskView.frame = self.bounds;
    self.contentView.center = [self popupEndingPoint];
}

- (void)didChangeStatusBarOrientation:(NSNotification*)notification {
    if (SYSTEM_VERSION_LESS_THAN_OR_EQUAL_TO(@"8.0")) {
        [self updateForInterfaceOrientation];
    }
}

#pragma mark - Popup Content Setup

- (CGFloat)contentHeight {
    CGFloat totalHeight = 0.0f;
    
    CGFloat maxWidth = self.theme.popupStyle == CNPPopupStyleCentered ? self.theme.preferredPopupWidth : self.bounds.size.width;
    maxWidth -= (self.theme.popupContentInsets.left + self.theme.popupContentInsets.right);
    
    // Title Calculation
    if (self.popupTitle) {
        CGRect titleSize = [self.popupTitle boundingRectWithSize:CGSizeMake(maxWidth, CGFLOAT_MAX)
                                                    options:NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading
                                                    context:nil];
        totalHeight += titleSize.size.height + 2;
    }
    
    // Labels & Images Calculation
    if (self.contents) {
        for (NSObject *content in self.contents) {
            if ([content isKindOfClass:[NSAttributedString class]]) {
                NSAttributedString *label = (NSAttributedString *)content;
                CGRect labelSize = [label boundingRectWithSize:CGSizeMake(maxWidth, CGFLOAT_MAX)
                                                       options:NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading
                                                       context:nil];
                totalHeight += labelSize.size.height + 2;
            }
            else if ([content isKindOfClass:[UIImage class]]) {
                UIImage *image = (UIImage *)content;
                totalHeight += image.size.height;
            }
        }
    }
    
    if (self.buttonTitles) {
        totalHeight += (50 * self.buttonTitles.count);
    }
    
    // Factor in padding
    totalHeight += (self.theme.contentVerticalPadding * ([self numberOfElements] - 1));
        
    return totalHeight;
}

- (NSUInteger)numberOfElements {
    return (self.popupTitle ? 1 : 0) + self.contents.count + self.buttonTitles.count + (self.destructiveButtonTitle ? 1 : 0);
}

- (CGSize)popupSize {
    if (self.theme.popupStyle == CNPPopupStyleFullscreen) {
        return self.bounds.size;
    }
    CGSize popupSize = CGSizeZero;
    if (self.theme.popupStyle != CNPPopupStyleCentered) {
        popupSize.width = self.bounds.size.width;
    }
    else {
        popupSize.width = self.theme.preferredPopupWidth;
    }
    popupSize.height = [self contentHeight] + (self.theme.popupContentInsets.top + self.theme.popupContentInsets.bottom);
    
    
    if (self.destructiveButtonTitle) {
        popupSize.height += 50;
    }
    
    // Check if height is less than minimum height set by theme
    if (popupSize.height < self.theme.minimumPopupHeight) {
        popupSize.height = self.theme.minimumPopupHeight;
    }
    
    return popupSize;
}

- (CNPTopBottomPadding) topBottomPadding {
    if (self.theme.popupStyle == CNPPopupStyleFullscreen) {
        CGFloat padding = (self.bounds.size.height - [self contentHeight]) / 2;
        return CNPTopBottomPaddingMake(padding, padding);
    }
    return CNPTopBottomPaddingMake(self.theme.popupContentInsets.top, self.theme.popupContentInsets.bottom);
}

- (CGPoint)popupStartingPoint {
    CGPoint point = CGPointZero;
    
    switch (self.theme.presentationStyle) {
        case CNPPopupPresentationStyleFadeIn:
            point = self.maskView.center;
            if (self.theme.popupStyle == CNPPopupStyleActionSheet) {
                point.y = self.maskView.center.y + ([self popupSize].height / 2);
            }
            break;
        case CNPPopupPresentationStyleSlideInFromTop:
            point.x = self.maskView.center.x;
            point.y =  0 - ([self popupSize].height / 2);
            break;
        case CNPPopupPresentationStyleSlideInFromBottom:
            point.x = self.maskView.center.x;
            point.y = self.bounds.size.height + ([self popupSize].height / 2);
            break;
        case CNPPopupPresentationStyleSlideInFromLeft:
            if (self.theme.popupStyle == CNPPopupStyleActionSheet) {
                point.y = self.maskView.center.y + ([self popupSize].height / 2);
            }
            else {
                point.y = self.maskView.center.y;
            }
            point.x = 0 - ([self popupSize].height / 2);
            break;
        case CNPPopupPresentationStyleSlideInFromRight:
            if (self.theme.popupStyle == CNPPopupStyleActionSheet) {
                point.y = self.maskView.center.y + ([self popupSize].height / 2);
            }
            else {
                point.y = self.maskView.center.y;
            }
            point.x = self.bounds.size.width + ([self popupSize].height / 2);
            break;
        default:
            break;
    }
    return point;
}

- (CGPoint)popupEndingPoint {
    CGPoint point = [self popupStartingPoint];
    
    if (self.theme.popupStyle == CNPPopupStyleActionSheet) {
        point.x = self.maskView.center.x;
        point.y = self.maskView.bounds.size.height - ([self popupSize].height / 2);
    }
    else {
        point = self.maskView.center;
    }
    return point;
    
}

- (void)setUpPopup {
    self.backgroundColor = [UIColor clearColor];
    
    // Set up mask view
    self.maskView = [[UIView alloc] initWithFrame:self.bounds];
    self.maskView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    self.maskView.alpha = 0.0;
    if (self.theme.maskType == CNPPopupMaskTypeDimmed) {
        self.maskView.backgroundColor = [UIColor colorWithWhite:0.0f alpha:0.5f];
    } else {
        self.maskView.backgroundColor = [UIColor clearColor];
    }
    [self addSubview:self.maskView];
    
    CGRect popupFrame = CGRectZero;
    popupFrame.size = [self popupSize];
    self.contentView = [[UIView alloc] initWithFrame:popupFrame];
    self.contentView.center = self.maskView.center;
    self.contentView.clipsToBounds = YES;
    self.contentView.backgroundColor = self.theme.backgroundColor;
    self.contentView.layer.cornerRadius = self.theme.popupStyle == CNPPopupStyleCentered ? self.theme.cornerRadius : 0.0f;
    [self.maskView addSubview:self.contentView];
    
    
    CGFloat maxWidth = self.theme.popupStyle == CNPPopupStyleCentered ? self.theme.preferredPopupWidth : self.bounds.size.width;
    maxWidth -= (self.theme.popupContentInsets.left + self.theme.popupContentInsets.right);
    
    if (self.popupTitle) {
        UILabel *title = [self multilineLabelWithAttributedString:self.popupTitle];
        [title setPreferredMaxLayoutWidth:maxWidth];
        [self.contentView addSubview:title];
    }
    
    if (self.contents) {
        for (NSObject *content in self.contents) {
            if ([content isKindOfClass:[NSAttributedString class]]) {
                UILabel *label = [self multilineLabelWithAttributedString:(NSAttributedString *)content];
                [label setPreferredMaxLayoutWidth:maxWidth];
                [self.contentView addSubview:label];
            }
            else if ([content isKindOfClass:[UIImage class]]) {
                UIImageView *imageView = [self centeredImageViewForImage:(UIImage *)content];
                [imageView sizeToFit];
                [self.contentView addSubview:imageView];
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
            [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:view
                                                                         attribute:NSLayoutAttributeTop
                                                                         relatedBy:NSLayoutRelationEqual
                                                                            toItem:self.contentView
                                                                         attribute:NSLayoutAttributeTop
                                                                        multiplier:1.0f
                                                                          constant:[self topBottomPadding].top]];
        }
        else {
            UIView *previousview = [self.contentView.subviews objectAtIndex:idx-1];
            [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:view
                                                                         attribute:NSLayoutAttributeTop
                                                                         relatedBy:NSLayoutRelationEqual
                                                                            toItem:previousview
                                                                         attribute:NSLayoutAttributeBottom
                                                                        multiplier:1.0f
                                                                          constant:self.theme.contentVerticalPadding]];
        }
        
        if ([view isKindOfClass:[UIButton class]]) {
            [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:view
                                                                         attribute:NSLayoutAttributeHeight
                                                                         relatedBy:NSLayoutRelationEqual
                                                                            toItem:nil
                                                                         attribute:NSLayoutAttributeNotAnAttribute
                                                                        multiplier:1.0f
                                                                          constant:50.0f]];
            [((UIButton *)view) addTarget:self action:@selector(actionButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        }
        
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:view
                                                                     attribute:NSLayoutAttributeLeft
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:self.contentView
                                                                     attribute:NSLayoutAttributeLeft
                                                                    multiplier:1.0f
                                                                      constant:self.theme.popupContentInsets.left]];
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:view
                                                                     attribute:NSLayoutAttributeRight
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:self.contentView
                                                                     attribute:NSLayoutAttributeRight
                                                                    multiplier:1.0f
                                                                      constant:-self.theme.popupContentInsets.right]];
        
        if (idx == self.contentView.subviews.count - 1) {
            [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:view
                                                                         attribute:NSLayoutAttributeBottom
                                                                         relatedBy:NSLayoutRelationEqual
                                                                            toItem:self.contentView
                                                                         attribute:NSLayoutAttributeBottom
                                                                        multiplier:1.0f
                                                                          constant:- ([self topBottomPadding].bottom + (self.destructiveButtonTitle ? 50.0f : 0))]];
        }
    }];
    
    
    if (self.destructiveButtonTitle) {
        UIButton *destructiveButton = [self destructiveButtonWithAttributedTitle:self.destructiveButtonTitle];
        [self.contentView addSubview:destructiveButton];
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:destructiveButton
                                                                     attribute:NSLayoutAttributeLeft
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:self.contentView
                                                                     attribute:NSLayoutAttributeLeft
                                                                    multiplier:1.0f
                                                                      constant:0]];
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:destructiveButton
                                                                     attribute:NSLayoutAttributeRight
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:self.contentView
                                                                     attribute:NSLayoutAttributeRight
                                                                    multiplier:1.0f
                                                                      constant:0]];
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:destructiveButton
                                                                     attribute:NSLayoutAttributeBottom
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:self.contentView
                                                                     attribute:NSLayoutAttributeBottom
                                                                    multiplier:1.0f
                                                                      constant:0]];
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:destructiveButton
                                                                     attribute:NSLayoutAttributeHeight
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:nil
                                                                     attribute:NSLayoutAttributeNotAnAttribute
                                                                    multiplier:1.0f
                                                                      constant:50.0f]];
        
        [destructiveButton addTarget:self action:@selector(actionButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        
    }
    
}

- (void)actionButtonPressed:(UIButton *)sender {
    [self dismissPopupControllerAnimated:YES withButtonTitle:[sender attributedTitleForState:UIControlStateNormal].string];
}

#pragma mark - Presentation

- (void)presentPopupControllerAnimated:(BOOL)flag {
    
    dispatch_async( dispatch_get_main_queue(), ^{
        // Prepare by adding to the top window.
        if(!self.superview){
            NSEnumerator *frontToBackWindows = [[[UIApplication sharedApplication] windows] reverseObjectEnumerator];
            for (UIWindow *window in frontToBackWindows) {
                if (window.windowLevel == UIWindowLevelNormal) {
                    [window addSubview:self];
                    // Before we calculate layout for containerView, make sure we are transformed for current orientation.
                    if (SYSTEM_VERSION_LESS_THAN_OR_EQUAL_TO(@"8.0")) {
                        [self updateForInterfaceOrientation];
                    }
                    [self setUpPopup];
                    break;
                }
            }
        }
        
        
        self.contentView.center = [self popupStartingPoint];
        [UIView animateWithDuration:flag ? 0.3f : 0.0f
                              delay:0
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:^{
                             self.maskView.alpha = 1.0f;
                             self.contentView.center = [self popupEndingPoint];
                         }
                         completion:^(BOOL finished) {
                             self.isShowing = YES;
                             if ([self.delegate respondsToSelector:@selector(popupControllerDidPresent:)]) {
                                 [self.delegate popupControllerDidPresent:self];
                             }
                         }];
    });
}

- (void)dismissPopupControllerAnimated:(BOOL)flag {
    [self dismissPopupControllerAnimated:flag withButtonTitle:nil];
}

- (void)dismissPopupControllerAnimated:(BOOL)flag withButtonTitle:(NSString *)title {
    dispatch_async( dispatch_get_main_queue(), ^{
        
        [UIView animateWithDuration:flag ? 0.3f : 0.0f
                              delay:0
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:^{
                             self.maskView.alpha = 0.0f;
                             self.contentView.center = [self popupStartingPoint];
                         }
                         completion:^(BOOL finished) {
                             [self removeFromSuperview];
                             self.maskView = nil;
                             self.contentView = nil;
                             self.isShowing = NO;
                             if ([self.delegate respondsToSelector:@selector(popupController:didDismissWithButtonTitle:)]) {
                                 [self.delegate popupController:self didDismissWithButtonTitle:title];
                             }
                         }];
    });
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
