//
//  UIImage+compare.h
//  ExtractCommonResource
//
//  Created by Zou Tan on 2019/3/26.
//  Copyright © 2019 ND. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <CoreGraphics/CoreGraphics.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSImage (compare)

- (CGSize)getPixleSize;

- (float)sameWithImage:(NSImage *)image;



@end

NS_ASSUME_NONNULL_END
