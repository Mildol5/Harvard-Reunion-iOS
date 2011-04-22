#import "AttendeesTableViewController.h"
#import "KGOTheme.h"
#import "KGORequestManager.h"

NSString * const AllReunionAttendeesPrefKey = @"AllAttendees";

@implementation AttendeesTableViewController

@synthesize attendees, eventTitle, request, tableView = _tableView;

- (void)dealloc
{
    self.attendees = nil;
    self.eventTitle = nil;
    [self.request cancel];
    self.request = nil;
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.title = @"Attendees";
    
    if (!self.attendees) {
        self.attendees = [[NSUserDefaults standardUserDefaults] objectForKey:AllReunionAttendeesPrefKey];
    }
    
    if (!self.attendees) {
        self.request = [[KGORequestManager sharedManager] requestWithDelegate:self module:@"attendees" path:@"all" params:nil];
        self.request.expectedResponseType = [NSArray class];
        if (self.request) {
            [self.request connect];
        }
    }
    
    if (!_sectionTitles) {
        NSMutableArray *titles = [NSMutableArray array];
        _sections = [[NSMutableDictionary alloc] init];
        
        for (NSDictionary *attendeeDict in self.attendees) {
            NSString *name = [attendeeDict objectForKey:@"display_name"];
            if (name.length) {
                NSString *firstLetter = [[name substringWithRange:NSMakeRange(0, 1)] capitalizedString];
                NSMutableArray *names = [_sections objectForKey:firstLetter];
                if (!names) {
                    names = [NSMutableArray array];
                    [_sections setObject:names forKey:firstLetter];
                    [titles addObject:firstLetter];
                }
                [names addObject:name];
            }
        }
        
        _sectionTitles = [[titles sortedArrayUsingSelector:@selector(compare:)] copy];
    }

    CGRect frame = CGRectMake(0, 44, self.view.frame.size.width, self.view.frame.size.height - 44);
    self.tableView = [[[UITableView alloc] initWithFrame:frame style:UITableViewStylePlain] autorelease];
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.separatorColor = [UIColor whiteColor];

    UIFont *font = [[KGOTheme sharedTheme] fontForThemedProperty:KGOThemePropertySectionHeaderGrouped];
    CGFloat hPadding = 20.0f;
    CGFloat viewHeight = font.pointSize + 24;
    
    CGSize size = [self.eventTitle sizeWithFont:font];
    UILabel *label = [[[UILabel alloc] initWithFrame:CGRectMake(hPadding,
                                                                floor((viewHeight - size.height) / 2),
                                                                self.tableView.bounds.size.width - hPadding * 2,
                                                                size.height)] autorelease];
    
    label.text = self.eventTitle;
    label.textColor = [[KGOTheme sharedTheme] textColorForThemedProperty:KGOThemePropertySectionHeaderGrouped];
    label.font = font;
    label.backgroundColor = [UIColor clearColor];
    
    UIView *labelContainer = [[[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0,
                                                                       self.tableView.bounds.size.width,
                                                                       viewHeight)] autorelease];
    labelContainer.backgroundColor = [[KGOTheme sharedTheme] backgroundColorForApplication];
    [labelContainer addSubview:label];
    
    [self.view addSubview:labelContainer];
    [self.view addSubview:self.tableView];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - KGORequestDelegate

- (void)requestWillTerminate:(KGORequest *)request
{
    self.request = nil;
}

- (void)request:(KGORequest *)request didReceiveResult:(id)result
{
    self.request = nil;
    self.attendees = result;
    
    [[NSUserDefaults standardUserDefaults] setObject:self.attendees forKey:AllReunionAttendeesPrefKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [self.tableView reloadData];
}

#pragma mark - Table view data source

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView
{
    return _sectionTitles;
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index
{
    return index;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return _sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[_sections objectForKey:[_sectionTitles objectAtIndex:section]] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
    
    NSArray *names = [_sections objectForKey:[_sectionTitles objectAtIndex:indexPath.section]];
    NSString *name = [names objectAtIndex:indexPath.row];
    cell.textLabel.text = name;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    return cell;
}

@end
