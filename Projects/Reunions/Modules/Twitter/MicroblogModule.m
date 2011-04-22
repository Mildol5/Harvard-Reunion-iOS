#import "MicroblogModule.h"
#import "KGOHomeScreenWidget.h"
#import "KGOTheme.h"
#import "UIKit+KGOAdditions.h"
#import "KGOAppDelegate+ModuleAdditions.h"
#import "KGOHomeScreenViewController.h"
#import "KGORequestManager.h"
#import "MITThumbnailView.h"
#import "Foundation+KGOAdditions.h"
#import <QuartzCore/QuartzCore.h>

// dimensions
#define BUTTON_WIDTH_IPHONE 120
#define BUTTON_HEIGHT_IPHONE 46

#define BUTTON_WIDTH_IPAD 80
#define BUTTON_HEIGHT_IPAD 100

#define BOTTOM_SHADOW_HEIGHT 8
#define LEFT_SHADOW_WIDTH 5

#define BUBBLE_HEIGHT_SIDEBAR 160

// tags
#define BUTTON_WIDGET_LABEL_TAG 324

NSString * const FacebookStatusDidUpdateNotification = @"FacebookUpdate";
NSString * const TwitterStatusDidUpdateNotification = @"TwitterUpdate";

@implementation MicroblogModule

@synthesize buttonImage, chatBubbleCaratOffset;

- (void)didLogin:(NSNotification *)aNotification
{
}

#pragma mark chat bubble widget

- (void)hideChatBubble:(NSNotification *)aNotification {
    self.chatBubble.hidden = YES;
}

- (UILabel *)chatBubbleTitleLabel {
    return _chatBubbleTitleLabel;
}

- (UILabel *)chatBubbleSubtitleLabel {
    return _chatBubbleSubtitleLabel;
}

- (MITThumbnailView *)chatBubbleThumbnail
{
    return  _chatBubbleThumbnail;
}

- (KGOHomeScreenWidget *)chatBubble
{
    if (!_chatBubble) {
        
        _chatBubble = [[KGOHomeScreenWidget alloc] initWithFrame:CGRectZero];
        _chatBubble.module = self;
        _chatBubble.overlaps = YES;
        _chatBubble.tag = CHAT_BUBBLE_TAG;
        
        UIImage *bubbleImage = [UIImage imageWithPathName:@"common/chatbubble-body"];
        bubbleImage = [bubbleImage stretchableImageWithLeftCapWidth:10 topCapHeight:10];
        UIImageView *bubbleView = [[[UIImageView alloc] initWithImage:bubbleImage] autorelease];
        
        UIImage *caratImage = [UIImage imageWithPathName:@"common/chatbubble-carat"];
        UIImageView *caratView = [[[UIImageView alloc] initWithImage:caratImage] autorelease];

        NSInteger numberOfLinesForSubtitle = 1;
        CGRect frame = bubbleView.frame;

        KGOAppDelegate *appDelegate = KGO_SHARED_APP_DELEGATE();
        KGONavigationStyle navStyle = [appDelegate navigationStyle];
        BOOL isTablet = (navStyle == KGONavigationStyleTabletSidebar);
        
        KGOHomeScreenViewController *homeVC = (KGOHomeScreenViewController *)[appDelegate homescreen];
        CGRect bounds = homeVC.springboardFrame;
        
        if (isTablet) {
            numberOfLinesForSubtitle = 2;
            frame = CGRectMake(5, bounds.size.height - BUBBLE_HEIGHT_SIDEBAR - BUTTON_HEIGHT_IPAD, 150, BUBBLE_HEIGHT_SIDEBAR);
            bubbleView.frame = CGRectMake(0, 0, frame.size.width, frame.size.height - caratView.frame.size.height);
            CGFloat x = floor(self.chatBubbleCaratOffset * bubbleView.frame.size.width - caratView.frame.size.width / 2 + LEFT_SHADOW_WIDTH);
            caratView.frame = CGRectMake(x, bubbleView.frame.size.height - BOTTOM_SHADOW_HEIGHT,
                                         caratView.frame.size.width,
                                         caratView.frame.size.height);
        } else {
            _chatBubble.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin;
            CGFloat x = BUTTON_WIDTH_IPHONE + 5 - caratView.frame.size.width;
            frame = CGRectMake(x, bounds.size.height - frame.size.height,
                               bounds.size.width - x,
                               bubbleView.frame.size.height);
            
            bubbleView.frame = CGRectMake(caratView.frame.size.width - LEFT_SHADOW_WIDTH,
                                          0,
                                          frame.size.width - caratView.frame.size.width,
                                          frame.size.height);

            CGFloat y = floor(self.chatBubbleCaratOffset * bubbleView.frame.size.height - caratView.frame.size.height / 2);
            caratView.frame = CGRectMake(0, y,
                                         caratView.frame.size.width,
                                         caratView.frame.size.height);
        }
        _chatBubble.frame = frame;
        [_chatBubble addSubview:bubbleView];
        [_chatBubble addSubview:caratView];
        
        NSLog(@"%@ %@", [caratView description], [bubbleView description]);
        
        CGFloat bubbleHPadding = 10;
        CGFloat bubbleVPadding = isTablet ? 8 : 6;
        frame = CGRectMake(bubbleHPadding + bubbleView.frame.origin.x,
                           bubbleVPadding,
                           bubbleView.frame.size.width - bubbleHPadding * 2,
                           floor(bubbleView.frame.size.height * (isTablet ? 0.5 : 0.6)) - bubbleVPadding);

        _chatBubbleTitleLabel = [[[UILabel alloc] initWithFrame:frame] autorelease];
        _chatBubbleTitleLabel.numberOfLines = 0;
        _chatBubbleTitleLabel.text = NSLocalizedString(@"Loading...", nil);
        _chatBubbleTitleLabel.font = [UIFont systemFontOfSize:13];
        _chatBubbleTitleLabel.backgroundColor = [UIColor clearColor];
        [_chatBubble addSubview:_chatBubbleTitleLabel];

        frame.origin.y = frame.size.height + bubbleVPadding * 2;
        frame.size.height = bubbleView.frame.size.height - frame.origin.y - bubbleVPadding * 2;

        if (isTablet) {
            CGFloat oldWidth = frame.size.width;
            frame.size.width = frame.size.height;
            _chatBubbleThumbnail = [[[MITThumbnailView alloc] initWithFrame:frame] autorelease];
            [_chatBubble addSubview:_chatBubbleThumbnail];
            frame.origin.x += frame.size.width + 10;
            frame.size.width = oldWidth - frame.size.width - 10;
        }
        
        _chatBubbleSubtitleLabel = [[[UILabel alloc] initWithFrame:frame] autorelease];
        _chatBubbleSubtitleLabel.numberOfLines = numberOfLinesForSubtitle;
        _chatBubbleSubtitleLabel.font = [UIFont systemFontOfSize:12];
        _chatBubbleSubtitleLabel.textColor = [UIColor colorWithWhite:0.3 alpha:1];
        _chatBubbleSubtitleLabel.backgroundColor = [UIColor clearColor];
        [_chatBubble addSubview:_chatBubbleSubtitleLabel];
        
        _chatBubble.hidden = YES;
    }
    
    
    KGOAppDelegate *appDelegate = KGO_SHARED_APP_DELEGATE();
    KGONavigationStyle navStyle = [appDelegate navigationStyle];
    KGOHomeScreenViewController *homeVC = (KGOHomeScreenViewController *)[appDelegate homescreen];
    CGRect frame = _chatBubble.frame;
    CGRect bounds = homeVC.springboardFrame;
    if (navStyle == KGONavigationStyleTabletSidebar) {
        frame.origin.y = bounds.size.height - BUBBLE_HEIGHT_SIDEBAR - BUTTON_HEIGHT_IPAD;
    } else {
        frame.origin.y = bounds.size.height - frame.size.height;
    }
    _chatBubble.frame = frame;
    
    return _chatBubble;
}

#pragma mark button widget

- (NSString *)labelText
{
    return _labelText;
}

- (void)setLabelText:(NSString *)labelText
{
    [_labelText release];
    _labelText = [labelText retain];
    if (_labelText) {
        UILabel *label = (UILabel *)[self.buttonWidget viewWithTag:BUTTON_WIDGET_LABEL_TAG];
        label.text = _labelText;
    }
}

- (KGOHomeScreenWidget *)buttonWidget {
    if (!self.labelText) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(didLogin:)
                                                     name:KGODidLoginNotification
                                                   object:nil];
        return nil;
    }
    
    if (!_buttonWidget) {
        CGRect frame = CGRectZero; // all frames are set at the end
        _buttonWidget = [[KGOHomeScreenWidget alloc] initWithFrame:frame];
        _buttonWidget.gravity = KGOLayoutGravityBottomLeft;
        _buttonWidget.behavesAsIcon = YES;
        _buttonWidget.module = self;
        
        UIImageView *imageView = [[[UIImageView alloc] initWithImage:self.buttonImage] autorelease];
        [_buttonWidget addSubview:imageView];
        
        UILabel *label = [[[UILabel alloc] initWithFrame:frame] autorelease];
        label.font = [UIFont systemFontOfSize:12];
        label.text = self.labelText;
        label.numberOfLines = 2;
        label.backgroundColor = [UIColor clearColor];
        label.textColor = [UIColor whiteColor];
        label.tag = BUTTON_WIDGET_LABEL_TAG;
        [_buttonWidget addSubview:label];
        
        KGOAppDelegate *appDelegate = KGO_SHARED_APP_DELEGATE();
        KGONavigationStyle navStyle = [appDelegate navigationStyle];
        
        if (navStyle == KGONavigationStyleTabletSidebar) {
            frame.size.width = BUTTON_WIDTH_IPAD;
            frame.size.height = BUTTON_HEIGHT_IPAD;
            _buttonWidget.frame = frame;
            
            // TODO: stop using magic numbers
            imageView.frame = CGRectMake(22, 5, 31, 31);
            label.frame = CGRectMake(5, 40, 65, 40);
            label.textAlignment = UITextAlignmentCenter;
        } else {
            frame.size.width = BUTTON_WIDTH_IPHONE;
            frame.size.height = BUTTON_HEIGHT_IPHONE;
            _buttonWidget.frame = frame;
            
            // TODO: when we have an image of the right size, don't specify width/height
            frame = CGRectMake(5, 5, 31, 31);
            imageView.frame = frame;
            
            CGFloat x = frame.origin.x + frame.size.width + 5;
            frame = CGRectMake(x, 5, BUTTON_WIDTH_IPHONE - x - 5, 31);
            label.frame = frame;
        }
    }
    return _buttonWidget;
}

- (NSArray *)widgetViews {
    NSDictionary *settings = [[NSUserDefaults standardUserDefaults] objectForKey:KGOUserPreferencesKey];
    if (!settings) {
        settings = [[KGO_SHARED_APP_DELEGATE() appConfig] objectForKey:@"DefaultUserSettings"];
    }
    NSArray *wantedWidgets = [settings arrayForKey:@"Widgets"];
    if (self.buttonWidget && [wantedWidgets containsObject:self.tag]) {
        return [NSArray arrayWithObjects:self.buttonWidget, self.chatBubble, nil];
    }
    return nil;
}

#pragma mark ipad animation

- (Class)feedViewControllerClass
{
    return [UIViewController class];
}

- (void)willShowModalFeedController
{
}

- (UIViewController *)modulePage:(NSString *)pageName params:(NSDictionary *)params
{
    UIViewController *vc = nil;
    if ([KGO_SHARED_APP_DELEGATE() navigationStyle] != KGONavigationStyleTabletSidebar) {
        if ([pageName isEqualToString:LocalPathPageNameHome]) {
            vc = [[[[self feedViewControllerClass] alloc] initWithStyle:UITableViewStylePlain] autorelease];
        }
        
    } else {
        if (_modalFeedController) {
            return nil;
        }
        
        [self willShowModalFeedController];
        
        // circumvent the app delegate and present our own thing
        UIViewController *homescreen = [KGO_SHARED_APP_DELEGATE() homescreen];
        
        UIViewController *feedVC = [[[[self feedViewControllerClass] alloc] initWithStyle:UITableViewStylePlain] autorelease];
        _modalFeedController = [[UINavigationController alloc] initWithRootViewController:feedVC];
        
        feedVC.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                                 target:self
                                                                                                 action:@selector(hideModalFeedController:)] autorelease];
        
        CGRect frame = self.chatBubble.frame;
        frame.size.height -= 15;
        _modalFeedController.view.frame = frame;
        
        feedVC.view.layer.cornerRadius = 6;
        _modalFeedController.view.layer.cornerRadius = 6;
        
        CGRect screenFrame = [(KGOHomeScreenViewController *)homescreen springboardFrame];
        CGFloat bottom = frame.origin.y + frame.size.height;
        CGFloat top = 48;
        frame = CGRectMake(10, top, screenFrame.size.width - 20, bottom - top);
        
        _scrim = [[UIView alloc] initWithFrame:CGRectMake(0, 0, screenFrame.size.width, screenFrame.size.height)];
        _scrim.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5];
        _scrim.alpha = 0;
        
        [homescreen.view addSubview:_scrim];
        [homescreen.view addSubview:_modalFeedController.view];
        
        // remove this temporarily to avoid animation artifacts
        UIBarButtonItem *item = feedVC.navigationItem.rightBarButtonItem;
        feedVC.navigationItem.rightBarButtonItem = nil;
        
        __block UIViewController *blockFeedVC = feedVC;
        [UIView animateWithDuration:0.4 animations:^(void) {
            _modalFeedController.view.frame = frame;
            _scrim.alpha = 1;
            
        } completion:^(BOOL finished) {
            blockFeedVC.navigationItem.rightBarButtonItem = item;
        }];
    }
    return vc;
}

- (void)hideModalFeedController:(id)sender
{
    CGRect frame = self.chatBubble.frame;
    frame.size.height -= 15;
    
    [UIView animateWithDuration:0.4 animations:^(void) {
        _modalFeedController.view.frame = frame;
        _scrim.alpha = 0;
        
    } completion:^(BOOL finished) {
        [_scrim removeFromSuperview];
        [_scrim release];
        _scrim = nil;
        
        [_modalFeedController.view removeFromSuperview];
        [_modalFeedController release];
        _modalFeedController = nil;
    }];
}

@end
