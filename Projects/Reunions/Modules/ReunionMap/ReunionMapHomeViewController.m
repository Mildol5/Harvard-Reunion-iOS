
/****************************************************************
 *
 *  Copyright 2011 The President and Fellows of Harvard College
 *  Copyright 2011 Modo Labs Inc.
 *
 *****************************************************************/

#import "ReunionMapHomeViewController.h"
#import "MapKit+KGOAdditions.h"
#import "MapModule.h"
#import <QuartzCore/QuartzCore.h>
#import "UIKit+KGOAdditions.h"
#import "KGOSidebarFrameViewController.h"
#import "KGOAppDelegate+ModuleAdditions.h"

@implementation ReunionMapHomeViewController

@synthesize startFrame, startRegion;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // region and annotations may be set before _mapView was set up
    if (self.annotations.count) {
        [_mapView addAnnotations:self.annotations];
        if (!_didSetRegion) {
            MKCoordinateRegion region = [MapHomeViewController regionForAnnotations:self.annotations restrictedToClass:NULL];
            if (region.center.latitude && region.center.longitude) {
                _mapView.region = region;
            }
        }
    } else {
        [_mapView centerAndZoomToDefaultRegion];
    }
    
    // set up search bar
    if ([KGO_SHARED_APP_DELEGATE() navigationStyle] == KGONavigationStyleTabletSidebar) {
        _searchController.showsSearchOverlay = NO;
    }

    if (_didSetRegion) {
        _didSetRegion = NO;
        
        _mapBorder.clipsToBounds = YES;
        _mapBorder.autoresizesSubviews = NO;
        
        CGRect mapEndFrame = _mapView.frame;

        // fake up our own autoresizing here
        KGOSidebarFrameViewController *homescreen = (KGOSidebarFrameViewController *)[KGO_SHARED_APP_DELEGATE() homescreen];
        CGFloat hScaling = homescreen.container.bounds.size.width / self.view.bounds.size.width;
        CGFloat vScaling = homescreen.container.bounds.size.height / self.view.bounds.size.height;
        
        CGPoint mapLowerRight = CGPointMake(round(hScaling * mapEndFrame.size.width),
                                            round(vScaling * mapEndFrame.size.height));
        
        mapEndFrame.size = CGSizeMake(mapLowerRight.x - mapEndFrame.origin.x, mapLowerRight.y - mapEndFrame.origin.y);
        
        CGRect mapStartFrame = [_mapView convertRect:mapEndFrame toView:self.view];
        CGRect borderEndFrame = _mapBorder.frame;
        CGRect borderStartFrame = self.startFrame;
        _mapBorder.frame = borderStartFrame;

        _mapView.region = self.endRegion;
        
        mapStartFrame = [self.view convertRect:mapStartFrame toView:_mapBorder];
        _mapView.frame = mapStartFrame;

        CGRect frame = mapStartFrame;
        frame.origin.x -= 4; // cheat to make alignment look better

        MKCoordinateRegion region = [_mapView convertRect:frame toRegionFromView:_mapBorder];
        _mapView.region = region;
        
        [UIView animateWithDuration:1
                              delay:0
                            options:0
                         animations:^(void) {
                             
            _mapView.frame = mapEndFrame;
            _mapBorder.frame = borderEndFrame;
            
        } completion:^(BOOL finished) {
            _mapBorder.autoresizesSubviews = YES;

        }];
    }
}

- (void)setEndRegion:(MKCoordinateRegion)endRegion
{
    _endRegion = endRegion;
    _didSetRegion = YES;
}

- (MKCoordinateRegion)endRegion
{
    return _endRegion;
}

@end
