//
//  MediaImageView.h
//  Reunions
//
//  Created by Brian Patt on 4/10/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface MediaContainerView : UIView {
    CGSize _previewSize;
    UIView *_previewView;
}

- (UIView *)previewView;

- (void)setPreviewSize:(CGSize)size;
- (void)initPreviewView:(UIView *)view;
- (void)setPreviewView:(UIView *)view;
+ (CGFloat)heightForImageSize:(CGSize)size fitToWidth:(CGFloat)width;

@end
