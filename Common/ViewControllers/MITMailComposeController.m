#import "MITMailComposeController.h"
#import <MessageUI/MFMailComposeViewController.h>

@implementation UIViewController (MITMailComposeController)

- (void)presentMailControllerWithEmail:(NSString *)email
                               subject:(NSString *)subject
                                  body:(NSString *)body
                              delegate:(id<MFMailComposeViewControllerDelegate>)delegate
{
	Class mailClass = (NSClassFromString(@"MFMailComposeViewController"));
	if ((mailClass != nil) && [mailClass canSendMail]) {
		
		MFMailComposeViewController *aController = [[[MFMailComposeViewController alloc] init] autorelease];
        aController.mailComposeDelegate = delegate;

		if (email != nil) {
            NSArray *toRecipient = [NSArray arrayWithObject:email]; 
            [aController setToRecipients:toRecipient];
        }
        if (subject != nil) {
            [aController setSubject:subject];
        }
        if (body != nil) {
            [aController setMessageBody:body isHTML:NO];
        }
        
        [self presentModalViewController:aController animated:YES];
		
	} else {
        NSMutableArray *array = [NSMutableArray array];
        if (subject != nil) {
            [array addObject:[NSString stringWithFormat:@"&subject=%@", [subject stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding]]];
        }
        if (body != nil) {
             [array addObject:[NSString stringWithFormat:@"&body=%@", [body stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding]]];
        }
        NSString *urlString = [NSString stringWithFormat:@"mailto://%@?%@",
                               (email != nil ? email : @""),
                               [array componentsJoinedByString:@"&"]];
        
		NSURL *externURL = [NSURL URLWithString:urlString];
        
		if ([[UIApplication sharedApplication] canOpenURL:externURL]) {
			[[UIApplication sharedApplication] openURL:externURL];
        }
	}
}

- (void)presentMailControllerWithEmail:(NSString *)email
                               HTMLsubject:(NSString *)subject
                                  body:(NSString *)body
                              delegate:(id<MFMailComposeViewControllerDelegate>)delegate
{
	Class mailClass = (NSClassFromString(@"MFMailComposeViewController"));
	if ((mailClass != nil) && [mailClass canSendMail]) {
		
		MFMailComposeViewController *aController = [[[MFMailComposeViewController alloc] init] autorelease];
        aController.mailComposeDelegate = delegate;
        
		if (email != nil) {
            NSArray *toRecipient = [NSArray arrayWithObject:email]; 
            [aController setToRecipients:toRecipient];
        }
        if (subject != nil) {
            [aController setSubject:subject];
        }
        if (body != nil) {
            [aController setMessageBody:body isHTML:YES];
        }
        
        [self presentModalViewController:aController animated:YES];
		
	} else {
        NSMutableArray *array = [NSMutableArray array];
        if (subject != nil) {
            [array addObject:[NSString stringWithFormat:@"&subject=%@", [subject stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding]]];
        }
        if (body != nil) {
            [array addObject:[NSString stringWithFormat:@"&body=%@", [body stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding]]];
        }
        NSString *urlString = [NSString stringWithFormat:@"mailto://%@?%@",
                               (email != nil ? email : @""),
                               [array componentsJoinedByString:@"&"]];
        
		NSURL *externURL = [NSURL URLWithString:urlString];
        
		if ([[UIApplication sharedApplication] canOpenURL:externURL]) {
			[[UIApplication sharedApplication] openURL:externURL];
        }
	}
}

@end

