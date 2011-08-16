
/****************************************************************
 *
 *  Copyright 2011 The President and Fellows of Harvard College
 *  Copyright 2011 Modo Labs Inc.
 *
 *****************************************************************/

#import <UIKit/UIKit.h>

@class FacebookComment;
@protocol FacebookUploadDelegate;
/*
@protocol FacebookCommentDelegate <NSObject>

- (void)didPostComment:(FacebookComment *)aComment;

@end
*/
@class FacebookParentPost;

@interface FacebookCommentViewController : UIViewController <UITextViewDelegate> {
    
    IBOutlet UITextView *_textView;
    IBOutlet UIView *_loadingViewContainer;
    IBOutlet UIActivityIndicatorView *_spinner;
    BOOL _textEditBegun;    
}

@property(nonatomic, retain) FacebookParentPost *post;
@property(nonatomic, retain) NSString *profileID;
//@property(nonatomic, assign) id<FacebookCommentDelegate> delegate;
@property(nonatomic, assign) id<FacebookUploadDelegate> delegate;

- (IBAction)submitButtonPressed:(id)sender;
- (IBAction)cancelButtonPressed:(id)sender;

@end
