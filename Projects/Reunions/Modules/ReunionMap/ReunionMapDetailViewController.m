#import "ReunionMapDetailViewController.h"
#import "KGOPlacemark.h"
#import "KGOTheme.h"
#import "KGOHTMLTemplate.h"
#import "ScheduleEventWrapper.h"
#import "KGOMapCategory.h"
#import "ReunionMapModule.h"
#import "KGOEvent.h"
#import <MapKit/MKAnnotation.h>
#import "Foundation+KGOAdditions.h"
#import "KGOAppDelegate+ModuleAdditions.h"
#import "CoreDataManager.h"
#import <QuartzCore/QuartzCore.h>
#import "UIKit+KGOAdditions.h"
#import "KGOSidebarFrameViewController.h"

#define IPAD_TABLEVIEW_ORIGIN_Y 500
#define CLOSE_BUTTON_TAG 15

@implementation ReunionMapDetailViewController

//@synthesize placemark,
@synthesize annotation, pager, tableView = _tableView;
/*
- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}
*/

- (void)loadView
{
    [super loadView];
    
    _currentTableWidth = 0;
    
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    
    if ([KGO_SHARED_APP_DELEGATE() navigationStyle] == KGONavigationStyleTabletSidebar) {
        _scrollView = [[[UIScrollView alloc] initWithFrame:self.view.bounds] autorelease];
        _scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _scrollView.bounces = NO;
        [_scrollView addSubview:self.tableView];
        _scrollView.delegate = self;
        _scrollView.contentSize = CGSizeMake(_scrollView.frame.size.width, 500 + self.tableView.frame.size.height);
        _scrollView.showsVerticalScrollIndicator = NO;
        _scrollView.showsHorizontalScrollIndicator = NO;
        _scrollView.clipsToBounds = NO;
        
        CGRect frame = self.tableView.frame;
        frame.origin.y = IPAD_TABLEVIEW_ORIGIN_Y;
        self.tableView.frame = frame;
        self.tableView.layer.cornerRadius = 5;
        self.tableView.backgroundColor = [UIColor whiteColor];
        self.tableView.scrollEnabled = NO;
        
        UIButton *closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
        closeButton.tag = CLOSE_BUTTON_TAG;
        UIImage *image = [UIImage imageWithPathName:@"common/window-close-button"];
        [closeButton setImage:image forState:UIControlStateNormal];
        CGRect buttonFrame = CGRectZero;
        buttonFrame.size = image.size;
        buttonFrame.origin.x = _scrollView.frame.size.width - image.size.width + 5;
        buttonFrame.origin.y = IPAD_TABLEVIEW_ORIGIN_Y - image.size.height + 5;
        closeButton.frame = buttonFrame;
        closeButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin;
        KGOSidebarFrameViewController *homescreen = (KGOSidebarFrameViewController *)[KGO_SHARED_APP_DELEGATE() homescreen];
        [closeButton addTarget:homescreen action:@selector(hideDetailViewController) forControlEvents:UIControlEventTouchUpInside];
        
        [self.view addSubview:_scrollView];
        [_scrollView addSubview:self.tableView];
        [_scrollView addSubview:closeButton];

    } else {
        [self.view addSubview:self.tableView];
    }
}

- (void)dealloc
{
    if (_placemarkInfoRequest) {
        [_placemarkInfoRequest cancel];
    }

    _webView.delegate = nil;
    [_webView release];
    _thumbView.delegate = nil;
    [_thumbView release];
    [_htmlTemplate release];
    [_placemarkInfo release];
    
    self.annotation = nil;
    self.pager = nil;
    
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark KGODetailPager

- (void)loadAnnotationContent
{
    if (_placemarkInfoRequest) {
        [_placemarkInfoRequest cancel];
        _placemarkInfoRequest = nil;
    }
    
    [_placemarkInfo release];
    _placemarkInfo = nil;
    [_image release];
    _image = nil;
    [_imageURL release];
    _imageURL = nil;
    
    if ([self.annotation isKindOfClass:[KGOPlacemark class]]) {
        KGOPlacemark *placemark = (KGOPlacemark *)self.annotation;
        if ([placemark.category.identifier isEqualToString:EventMapCategoryName]) {
            KGOEvent *storedEvent = [KGOEvent eventWithID:placemark.identifier];
            if (storedEvent) {
                self.annotation = [[ScheduleEventWrapper alloc] initWithKGOEvent:storedEvent];
            }
        }
    }
    
    // set up webview
    
    CGRect webViewFrame = CGRectMake(10, 10, self.tableView.frame.size.width - 40, 1);
    if (!_webView) {
        _webView = [[UIWebView alloc] initWithFrame:webViewFrame];
        _webView.delegate = self;
    } else {
        _webView.frame = webViewFrame;
    }
    
    if ([self.annotation isKindOfClass:[KGOPlacemark class]]) {
        KGOPlacemark *placemark = (KGOPlacemark *)self.annotation;
        _placemarkInfo = [placemark.info copy];
        _imageURL = [placemark.photoURL copy];
        _image = [[UIImage imageWithData:placemark.photo] retain];
        
    } else if ([self.annotation isKindOfClass:[ScheduleEventWrapper class]]) {
        NSString *placemarkID = [(ScheduleEventWrapper *)self.annotation placemarkID];
        if (placemarkID) {
            NSPredicate *pred = [NSPredicate predicateWithFormat:@"identifier = %@", placemarkID];
            NSArray *matches = [[CoreDataManager sharedManager] objectsForEntity:KGOPlacemarkEntityName matchingPredicate:pred];
            if (matches.count) {
                KGOPlacemark *placemark = [matches objectAtIndex:0];
                _placemarkInfo = [placemark.info copy];
                _imageURL = [placemark.photoURL copy];
                _image = [[UIImage imageWithData:placemark.photo] retain];
                
            } else {            
                NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:placemarkID, @"q", nil];
                _placemarkInfoRequest = [[KGORequestManager sharedManager] requestWithDelegate:self
                                                                                        module:@"map"
                                                                                          path:@"search"
                                                                                        params:params];
                [_placemarkInfoRequest connect];
            }
        }
    }
    
    [self loadDetailSection];
}

- (void)loadDetailSection
{
    
    if (_placemarkInfo) {
        NSDictionary *replacements = [NSDictionary dictionaryWithObjectsAndKeys:_placemarkInfo, @"BODY", nil];
        NSString *string = [_htmlTemplate stringWithReplacements:replacements];
        [_webView loadHTMLString:string baseURL:nil];
    }
    
    // set up photo
    
    if (_image || _imageURL) {
        if (!_thumbView) {
            _thumbView = [[MITThumbnailView alloc] initWithFrame:CGRectMake(10, 10, 1, 1)];
            _thumbView.delegate = self;
        }
        
        if (_image) {
            CGFloat maxWidth = self.tableView.frame.size.width - 40;
            CGFloat ratio = maxWidth / _image.size.width;
            CGRect frame = _thumbView.frame;
            frame.size = CGSizeMake(floor(ratio * _image.size.width), floor(ratio * _image.size.height));
            _thumbView.frame = frame;
            _thumbView.imageData = UIImagePNGRepresentation(_image);
            [_thumbView displayImage];
            
        } else {
            _thumbView.imageURL = _imageURL;
            _thumbView.imageData = nil;
            [_thumbView loadImage];
        }
        
    } else if (_thumbView) {
        [_thumbView removeFromSuperview];
        [_thumbView release];
        _thumbView = nil;
    }
}

- (void)pager:(KGODetailPager*)pager showContentForPage:(id<KGOSearchResult>)content {
    if ([content isKindOfClass:[KGOPlacemark class]]) {
        self.annotation = (id<MKAnnotation, KGOSearchResult>)content;
        _headerView.detailItem = self.annotation;
        [self loadAnnotationContent];
        [self.tableView reloadData];
    }
}

#pragma mark - Table header

- (void)headerViewFrameDidChange:(KGODetailPageHeaderView *)headerView
{
    self.tableView.tableHeaderView = _headerView;
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor clearColor];

    [self loadAnnotationContent]; // load annotation before inspecting it
    
    if ([self.annotation isKindOfClass:[KGOPlacemark class]]) {
        self.title = @"Building Detail";
    } else if ([self.annotation isKindOfClass:[ScheduleEventWrapper class]]) {
        self.title = @"Event Location";
    }
    
    if (self.pager) {
        self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithCustomView:self.pager] autorelease];
    }
    
    if (!_headerView) {
        _headerView = [[ReunionMapDetailHeaderView alloc] initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width, 1)];
        _headerView.delegate = self;
        _headerView.showsBookmarkButton = YES;
    }
    _headerView.detailItem = self.annotation;
    self.tableView.tableHeaderView = _headerView;
    
    if (!_htmlTemplate) {
        _htmlTemplate = [[KGOHTMLTemplate templateWithPathName:@"modules/map/detail.html"] retain];
    }
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    // make sure at least 400px of the table height is visible
    [_scrollView scrollRectToVisible:CGRectMake(0, 500, 1, 400) animated:YES];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)updateScrollView
{
    NSInteger count = [self numberOfSectionsInTableView:self.tableView];
    CGFloat height = 0;
    CGFloat lastOriginY = 0;
    for (NSInteger i = 0; i < count; i++) {
        CGRect rect = [self.tableView rectForSection:i];
        height += rect.origin.y - lastOriginY;
        height += rect.size.height;
    }

    //UIView *closeButton = [_scrollView viewWithTag:CLOSE_BUTTON_TAG];
    //CGRect frame = closeButton.frame;
    //frame.origin.x = _scrollView.frame.size.width - floor(closeButton.frame.size.width / 2);
    //closeButton.frame = frame;
    
    _scrollView.contentSize = CGSizeMake(_scrollView.frame.size.width, IPAD_TABLEVIEW_ORIGIN_Y + height);
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    [self updateScrollView];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if ([self.annotation isKindOfClass:[ScheduleEventWrapper class]] && _placemarkInfo) {
        return 3;
    }
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (_currentTableWidth && _currentTableWidth != tableView.frame.size.width) {
        [self loadDetailSection];
    }
    _currentTableWidth = tableView.frame.size.width;
    
    return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat height = tableView.rowHeight;
    if ((indexPath.section == 1 && [self.annotation isKindOfClass:[KGOPlacemark class]])
        || indexPath.section == 2
    ) {
        height = _webView.frame.size.height + 20;
        if (_thumbView) {
            height += _thumbView.frame.size.height + 10;
        }
    }
    return height;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *cellIdentifier = [NSString stringWithFormat:@"%d", indexPath.section];
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier] autorelease];
    }
    
    if (indexPath.section == 0 && [self.annotation isKindOfClass:[ScheduleEventWrapper class]]) {
        cell.textLabel.text = @"More event info";
        cell.accessoryView = [[KGOTheme sharedTheme] accessoryViewForType:KGOAccessoryTypeChevron];
        cell.selectionStyle = UITableViewCellSelectionStyleGray;
        
    } else if (indexPath.section == 0 || (indexPath.section == 1 && [self.annotation isKindOfClass:[ScheduleEventWrapper class]])) {
        cell.textLabel.text = @"View Location in Google Maps";
        cell.accessoryView = [[KGOTheme sharedTheme] accessoryViewForType:KGOAccessoryTypeExternal];
        cell.selectionStyle = UITableViewCellSelectionStyleGray;
        
    } else {
        if (![_webView isDescendantOfView:cell.contentView]) {
            [cell.contentView addSubview:_webView];
        }
        
        if (_thumbView) {
            if (![_thumbView isDescendantOfView:cell.contentView]) {
                [cell.contentView addSubview:_thumbView];
            }
            
            CGFloat y = _thumbView.frame.origin.y + _thumbView.frame.size.height;
            if (y > 11) {
                CGFloat desiredWebViewWidth = tableView.frame.size.width - 40;
                CGFloat actualWebViewWidth = _webView.frame.size.width;
                _webView.frame = CGRectMake(10, y + 10, desiredWebViewWidth, _webView.frame.size.height);
                if (actualWebViewWidth != desiredWebViewWidth) {
                    NSDictionary *replacements = [NSDictionary dictionaryWithObjectsAndKeys:_placemarkInfo, @"BODY", nil];
                    NSString *string = [_htmlTemplate stringWithReplacements:replacements];
                    [_webView loadHTMLString:string baseURL:nil];
                }
            }
        }

        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *search = nil;
    
    if (indexPath.section == 0 && [self.annotation isKindOfClass:[ScheduleEventWrapper class]]) {
        // more info
        NSIndexPath *currentIndexPath = [NSIndexPath indexPathForRow:0 inSection:0];
        NSString *sectionID = @"aSectionID"; // usually this is date strings
        NSArray *events = [NSArray arrayWithObject:self.annotation];
        NSDictionary *eventsBySection = [NSDictionary dictionaryWithObject:events forKey:sectionID];
        NSArray *sections = [NSArray arrayWithObject:sectionID];
        
        NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
                                currentIndexPath, @"currentIndexPath",
                                eventsBySection, @"eventsBySection",
                                sections, @"sections",
                                nil];
        [KGO_SHARED_APP_DELEGATE() showPage:LocalPathPageNameDetail forModuleTag:@"schedule" params:params];
        
        
    } else if (indexPath.section == 0 || (indexPath.section == 1 && [self.annotation isKindOfClass:[ScheduleEventWrapper class]])) {
        // google maps
        
        if (self.annotation.coordinate.latitude || self.annotation.coordinate.longitude) {
            search = [NSString stringWithFormat:@"%.5f,%.5f", self.annotation.coordinate.latitude, self.annotation.coordinate.longitude];
        } else if ([self.annotation isKindOfClass:[KGOPlacemark class]] && [(KGOPlacemark *)self.annotation street]) {
            search = [(KGOPlacemark *)self.annotation street];
        } else if ([self.annotation isKindOfClass:[ScheduleEventWrapper class]] && [(ScheduleEventWrapper *)self.annotation location]) {
            search = [(ScheduleEventWrapper *)self.annotation location];
        }
        
        NSString *urlString = [NSString stringWithFormat:@"http://maps.google.com/maps?q=%@", [search stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
        
        NSURL *url = [NSURL URLWithString:urlString];
        if ([[UIApplication sharedApplication] canOpenURL:url]) {
            [[UIApplication sharedApplication] openURL:url];
        }
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - Web view delegate

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    CGRect frame = webView.frame;
    CGSize size = [webView sizeThatFits:CGSizeMake(1, 1)];
    if (size.height != frame.size.height) {
        frame.size.height = size.height;
        webView.frame = frame;
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:1]
                      withRowAnimation:UITableViewRowAnimationNone];
    }
}

#pragma mark - Thumbnail delegate

- (void)thumbnail:(MITThumbnailView *)thumbnail didLoadData:(NSData *)data
{
    if ([self.annotation isKindOfClass:[KGOPlacemark class]]) {
        KGOPlacemark *placemark = (KGOPlacemark *)self.annotation;
        
        if ([thumbnail.imageURL isEqualToString:placemark.photoURL]) {
            placemark.photo = data;
            
            UIImage *image = [UIImage imageWithData:data];
            CGFloat maxWidth = self.view.frame.size.width - 40;
            CGFloat ratio = maxWidth / image.size.width;
            CGRect frame = thumbnail.frame;
            frame.size = CGSizeMake(floor(ratio * image.size.width), floor(ratio * image.size.height));
            thumbnail.frame = frame;
            [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:1]
                          withRowAnimation:UITableViewRowAnimationNone];
        }
        
    }
}

#pragma mark KGORequestDelegate

- (void)request:(KGORequest *)request didReceiveResult:(id)result
{
    NSArray *results = [result arrayForKey:@"results"];
    for (NSDictionary *aDictionary in results) {
        NSString *identifer = [aDictionary stringForKey:@"id" nilIfEmpty:YES];
        if ([identifer isEqualToString:self.annotation.identifier]) {
            KGOPlacemark *placemark = [KGOPlacemark placemarkWithDictionary:aDictionary];
            NSLog(@"i am a placemark: %@", placemark);
            _placemarkInfo = [placemark.info copy];
            _imageURL = [placemark.photoURL copy];
            [self loadDetailSection];
            [self.tableView reloadData];
        }
    }
}

- (void)requestWillTerminate:(KGORequest *)request
{
    _placemarkInfoRequest = nil;
}

@end
