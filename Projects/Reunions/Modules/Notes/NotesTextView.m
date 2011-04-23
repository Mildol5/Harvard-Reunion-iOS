//
//  NotesTextView.m
//  Reunions
//
//  Created by Muhammad J Amjad on 4/15/11.
//  Copyright 2011 ModoLabs Inc. All rights reserved.
//

#import "NotesTextView.h"
#import "UIKit+KGOAdditions.h"
#import "KGOTheme.h"
#import "CoreDataManager.h"
#import "MITMailComposeController.h"


#define MIN_HEIGHT = 250
#define MAX_HEIGHT = 350;


@implementation NotesTextView
@synthesize delegate;

- (id)initWithFrame:(CGRect)frame titleText:(NSString * ) titleText detailText: (NSString *) dateText noteText: (NSString *) noteText note:(Note *) savedNote firstResponder:(BOOL) firstResponder
{
    if (frame.size.height < 500)
        frame.size.height = 500;
    
    else if (frame.size.height > 800)
        frame.size.height = 800;
    
    self = [super initWithFrame:frame];
    if (self) {
        UIFont *fontTitle = [[KGOTheme sharedTheme] fontForThemedProperty:KGOThemePropertyContentTitle];
        CGSize titleSize = [titleText sizeWithFont:fontTitle];
        UILabel * titleTextLabel = [[UILabel alloc] initWithFrame:CGRectMake(5, 5, self.frame.size.width - 130, titleSize.height + 5.0)];
        titleTextLabel.text = titleText;
        titleTextLabel.font = fontTitle;
        titleTextLabel.numberOfLines = 1;
        titleTextLabel.lineBreakMode = UILineBreakModeTailTruncation;
        titleTextLabel.textColor = [UIColor blackColor];
        titleTextLabel.backgroundColor = [UIColor clearColor];
        
        UIFont *fontDetail = [[KGOTheme sharedTheme] fontForThemedProperty:KGOThemePropertyContentSubtitle];
        CGSize detailSize = [dateText sizeWithFont:fontTitle];
        UILabel * detailTextLabel = [[UILabel alloc] initWithFrame:CGRectMake(5, titleTextLabel.frame.size.height + 10, self.frame.size.width - 130, detailSize.height + 5.0)];
        detailTextLabel.text = dateText;
        detailTextLabel.font = fontDetail;
        detailTextLabel.numberOfLines = 1;
        detailTextLabel.lineBreakMode = UILineBreakModeTailTruncation;
        detailTextLabel.textColor = [UIColor blackColor];
        detailTextLabel.backgroundColor = [UIColor clearColor];
        
        UIImage *printButtonImage = [UIImage imageWithPathName:@"common/unread-message.png"];
        UIImage *shareButtonImage = [UIImage imageWithPathName:@"common/share.png"];
         UIImage *deleteButtonImage = [UIImage imageWithPathName:@"common/subheadbar_button.png"];
        
        CGFloat buttonX = self.frame.size.width - deleteButtonImage.size.width - shareButtonImage.size.width - printButtonImage.size.width - 20;
        CGFloat buttonY = 5;
        
        printButton = [[UIButton buttonWithType:UIButtonTypeCustom] retain];
        printButton.frame = CGRectMake(buttonX, buttonY, printButtonImage.size.width, printButtonImage.size.height);
        [printButton setImage:printButtonImage forState:UIControlStateNormal];
        [printButton setImage:[UIImage imageWithPathName:@"common/unread-message.png"] forState:UIControlStateHighlighted];
        
        [printButton addTarget:self action:@selector(printButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        
        buttonX += printButtonImage.size.width + 5;
        
        UIButton * shareButton = [[UIButton buttonWithType:UIButtonTypeCustom] retain];
        shareButton.frame = CGRectMake(buttonX, buttonY, shareButtonImage.size.width, shareButtonImage.size.height);
        [shareButton setImage:shareButtonImage forState:UIControlStateNormal];
        [shareButton setImage:[UIImage imageWithPathName:@"common/share_pressed.png"] forState:UIControlStateHighlighted];

        [shareButton addTarget:self action:@selector(shareButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        
       
        buttonX += shareButtonImage.size.width + 5;
        
        UIButton * deleteButton = [[UIButton buttonWithType:UIButtonTypeCustom] retain];
        deleteButton.frame = CGRectMake(buttonX, buttonY, deleteButtonImage.size.width, deleteButtonImage.size.height);
        [deleteButton setImage:deleteButtonImage forState:UIControlStateNormal];
        [deleteButton setImage:[UIImage imageWithPathName:@"common/subheadbar_button.png"] forState:UIControlStateHighlighted];
        
        [deleteButton addTarget:self action:@selector(deleteButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        
        [self addSubview:titleTextLabel];
        [self addSubview:detailTextLabel];
        [self addSubview:printButton];
        [self addSubview:shareButton];
        [self addSubview:deleteButton];

        
        UIImage * image = [UIImage imageWithPathName:@"modules/schedule/faketop-above-selection.png"];
        UIImageView * sectionDivider;
        if (image){
            sectionDivider = [[UIImageView alloc] initWithImage:[image stretchableImageWithLeftCapWidth:0 topCapHeight:0]];
            sectionDivider.frame = CGRectMake(15, 
                                              titleTextLabel.frame.size.height + detailTextLabel.frame.size.height + 15, 
                                              self.frame.size.width, 
                                              4);
            
            [self addSubview:sectionDivider];
        }
        
        
        
        if (nil == detailsView) {
            
            detailsView = [[UITextView alloc] initWithFrame:CGRectMake(0, 
                                                                       titleTextLabel.frame.size.height + detailTextLabel.frame.size.height + 25, 
                                                                       self.frame.size.width, 
                                                                       self.frame.size.height - titleTextLabel.frame.size.height - detailTextLabel.frame.size.height - 25)];
            detailsView.delegate = self;
            detailsView.backgroundColor = [UIColor clearColor];
            
            [self addSubview:detailsView];
            
            detailsView.font = [[KGOTheme sharedTheme] fontForThemedProperty:KGOThemePropertyByline];
            detailsView.text = noteText;
            
            if (firstResponder == YES) {
                [detailsView becomeFirstResponder];
            }

        }
        
        self.backgroundColor = [UIColor clearColor];
        
        if (nil != note)
            [note release];
        
        note = [savedNote retain];
    }
    return self;
}

-(void) printButtonPressed: (id) sender {
    
    NSString * noteString = detailsView.text;
    NSArray * splitArrayPeriod = [noteString componentsSeparatedByString:@"."];
    NSArray * splitArrayNewLine = [noteString componentsSeparatedByString:@"\n"];
    
    NSArray * splitArray;
    
    if ([[splitArrayPeriod objectAtIndex:0] length] < [[splitArrayNewLine objectAtIndex:0] length])
        splitArray = splitArrayPeriod;
    
    else
        splitArray = splitArrayNewLine;
    
    NSString * textToPrint = [NSString stringWithFormat:@"%@:\n\n%@", [splitArray objectAtIndex:0], detailsView.text];
    
    [self printContent:textToPrint jobTitle:[splitArray objectAtIndex:0] fromButton:printButton];
}

-(void) shareButtonPressed: (id) sender {
    
    NSString * noteString = detailsView.text;
    NSArray * splitArrayPeriod = [noteString componentsSeparatedByString:@"."];
    NSArray * splitArrayNewLine = [noteString componentsSeparatedByString:@"\n"];
    
    NSArray * splitArray;
    
    if ([[splitArrayPeriod objectAtIndex:0] length] < [[splitArrayNewLine objectAtIndex:0] length])
        splitArray = splitArrayPeriod;
    
    else
        splitArray = splitArrayNewLine;
    
    NSString * emailSubject = note.title;
    
    if (nil == note.eventIdentifier)
        emailSubject = [NSString stringWithFormat:@"Note: %@",[splitArray objectAtIndex:0]];
    
    [self.delegate presentMailControllerWithEmail: nil
                                          subject: emailSubject
                                             body: noteString                                        
                                         delegate:self];
    
}

- (void) deleteButtonPressed: (id) sender {
    
    UIActionSheet * deleteActionSheet = [[UIActionSheet alloc] initWithTitle:@"Are you sure you want to delete the note?" 
                                                                    delegate:self 
                                                           cancelButtonTitle:@"Cancel" 
                                                      destructiveButtonTitle:@"Delete" 
                                                           otherButtonTitles:nil];
    
    [deleteActionSheet showInView:self];
    [deleteActionSheet release];
}


- (void)dealloc
{
    [super dealloc];
}

- (void) printContent: (NSString *) textToPrint jobTitle:(NSString *) jobTitle fromButton:(UIButton *) button{
    
    UIPrintInteractionController *pic = [UIPrintInteractionController sharedPrintController];
    pic.delegate = self;
    
    UIPrintInfo *printInfo = [UIPrintInfo printInfo];
    printInfo.outputType = UIPrintInfoOutputGeneral;
    printInfo.jobName = jobTitle;
    pic.printInfo = printInfo;
    
    UISimpleTextPrintFormatter *textFormatter = [[UISimpleTextPrintFormatter alloc]
                                                 initWithText:textToPrint];
    textFormatter.startPage = 0;
    textFormatter.contentInsets = UIEdgeInsetsMake(72.0, 72.0, 72.0, 72.0); // 1 inch margins
    textFormatter.maximumContentWidth = 6 * 72.0;
    pic.printFormatter = textFormatter;
    [textFormatter release];
    pic.showsPageRange = YES;
    
    void (^completionHandler)(UIPrintInteractionController *, BOOL, NSError *) =
    ^(UIPrintInteractionController *printController, BOOL completed, NSError *error) {
        if (!completed && error) {
            NSLog(@"Printing could not complete because of error: %@", error);
        }
    };
    
    if (nil != button)
        [pic presentFromRect:button.frame inView:button animated:YES completionHandler:completionHandler];
    
    else
        [pic presentFromRect:self.frame inView:self animated:YES completionHandler:completionHandler];
}
        

#pragma mark
#pragma mark UITextViewDelegate

- (void)textViewDidEndEditing:(UITextView *)textView {
    
    if (nil == note) {
        
    }
    
    NSString * noteString = detailsView.text;
    NSArray * splitArrayPeriod = [noteString componentsSeparatedByString:@"."];
    NSArray * splitArrayNewLine = [noteString componentsSeparatedByString:@"\n"];
    
    NSArray * splitArray;
    
    if ([[splitArrayPeriod objectAtIndex:0] length] < [[splitArrayNewLine objectAtIndex:0] length])
        splitArray = splitArrayPeriod;
    
    else
        splitArray = splitArrayNewLine;
    
    if (nil == note.eventIdentifier)
        note.title = [splitArray objectAtIndex:0];
    
    note.details = noteString;
    
    [[CoreDataManager sharedManager] saveData];
    
}

#pragma mark
#pragma mark MFMailComposeViewControllerDelegate

- (void) mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error {
    
    [self.delegate dismissModalViewControllerAnimated:YES];
}

#pragma mark
#pragma mark UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    if (buttonIndex == 0) {// destructive button pressed
        NSLog(@"delete button pressed from notes-listview");
    }
}


- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
    
    if (buttonIndex == 0) {// destructive button pressed
        NSLog(@"action sheet dismissed from view");
        
        [self removeFromSuperview];
        [self.delegate deleteNoteAndReload:note];

    }
}

@end
