//
//  UIImage+compare.m
//  ExtractCommonResource
//
//  Created by Zou Tan on 2019/3/26.
//  Copyright © 2019 ND. All rights reserved.
//

#import "UIImage+compare.h"

#define kCompareSize 8     // size for 8 * 8

@implementation NSImage (compare)

- (CGSize)getPixleSize {
    CGImageRef cgimage = [self nsImageToCGImageRef];
    return CGSizeMake(CGImageGetWidth(cgimage), CGImageGetHeight(cgimage));
}

- (CGImageRef)nsImageToCGImageRef {
    
    NSData * imageData = [self TIFFRepresentation];
    CGImageRef imageRef;
    
    CGImageSourceRef imageSource = CGImageSourceCreateWithData((CFDataRef)imageData,  NULL);
    imageRef = CGImageSourceCreateImageAtIndex(imageSource, 0, NULL);
    return imageRef;
}

- (float)sameWithImage:(NSImage *)image {
    int ArrSize = kCompareSize * kCompareSize + 1, a[ArrSize], b[ArrSize], i, j, grey, sum = 0;
    CGSize size = {kCompareSize,kCompareSize};
    NSImage *imga = [self imageResize:size];
    NSImage *imgb = [image imageResize:size];//缩小图片尺寸
    
    a[ArrSize] = 0;
    b[ArrSize] = 0;
    CGPoint point;
    for (i = 0 ; i < kCompareSize; i++) {//计算a的灰度
        for (j = 0; j < kCompareSize; j++) {
            point.x = i;
            point.y = j;
            grey = ToGrey([self UIcolorToRGB:[imga colorAtPixel:point]]);
            a[kCompareSize * i + j] = grey;
            a[ArrSize] += grey;
            }
        }
    a[ArrSize] /= (ArrSize - 1);//灰度平均值
     for (i = 0 ; i < kCompareSize; i++) {//计算b的灰度
         for (j = 0; j < kCompareSize; j++) {
            point.x = i;
            point.y = j;
            grey = ToGrey([self UIcolorToRGB:[imgb colorAtPixel:point]]);
            b[kCompareSize * i + j] = grey;
            b[ArrSize] += grey;
            }
        }
    b[ArrSize] /= (ArrSize - 1);//灰度平均值
    for (i = 0 ; i < ArrSize ; i++) {//灰度分布计算
        a[i] = (a[i] < a[ArrSize] ? 0 : 1);
        b[i] = (b[i] < b[ArrSize] ? 0 : 1);
    }
    ArrSize -= 1;
    for (i = 0 ; i < ArrSize ; i++) {
        sum += (a[i] == b[i] ? 1 : 0);
    }
//    return sum * 1.0 / ArrSize;
    
    return sum * 1.0 / ArrSize;
}

- (NSColor *)colorAtPixel:(CGPoint)point {//获取指定point位置的RGB
    // Cancel if point is outside image coordinates
    if (!CGRectContainsPoint(CGRectMake(0.0f, 0.0f, self.size.width, self.size.height), point)) { return nil; }
    NSInteger   pointX  = trunc(point.x);
    NSInteger   pointY  = trunc(point.y);
    CGImageRef  cgImage = [self nsImageToCGImageRef];
    NSUInteger  width   = self.size.width;
    NSUInteger  height  = self.size.height;
    int bytesPerPixel   = 4;
    int bytesPerRow     = bytesPerPixel * 1;
    NSUInteger bitsPerComponent = 8;
    unsigned char pixelData[4] = { 0, 0, 0, 0 };
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(pixelData, 1, 1, bitsPerComponent, bytesPerRow, colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    
    CGColorSpaceRelease(colorSpace);
    CGContextSetBlendMode(context, kCGBlendModeCopy);
    // Draw the pixel we are interested in onto the bitmap context
    CGContextTranslateCTM(context, -pointX, pointY-(CGFloat)height);
    CGContextDrawImage(context, CGRectMake(0.0f, 0.0f, (CGFloat)width, (CGFloat)height), cgImage);
    CGContextRelease(context);
    // Convert color values [0..255] to floats [0.0..1.0]
    CGFloat red   = (CGFloat)pixelData[0] / 255.0f;
    CGFloat green = (CGFloat)pixelData[1] / 255.0f;
    CGFloat blue  = (CGFloat)pixelData[2] / 255.0f;
    CGFloat alpha = (CGFloat)pixelData[3] / 255.0f;
    return [NSColor colorWithRed:red green:green blue:blue alpha:alpha];
}

- (unsigned int)UIcolorToRGB:(NSColor *)color{//UIColor转16进制RGB
    unsigned int RGB,R,G,B;
    RGB = R = G = B = 0x00000000;
    CGFloat r,g,b,a;
    [color getRed:&r green:&g blue:&b alpha:&a];
    R = r * 256 ;
    G = g * 256 ;
    B = b * 256 ;
    RGB = (R << 16) | (G << 8) | B ;
    return RGB;
}

unsigned int ToGrey(unsigned int rgb){//RGB计算灰度
    unsigned int blue   = (rgb & 0x000000FF) >> 0;
    unsigned int green  = (rgb & 0x0000FF00) >> 8;
    unsigned int red    = (rgb & 0x00FF0000) >> 16;
    return ( red*38 +  green * 75 +  blue * 15 )>>7;
}

- (NSImage *)imageResize:(CGSize)size {
    NSImage *newImage = [[NSImage alloc] initWithSize:size];
    
    [newImage lockFocus];
    CGSize fromSize = [self getPixleSize];
    [newImage drawInRect:NSMakeRect(0, 0, size.width, size.height) fromRect:NSMakeRect(0, 0, fromSize.width, fromSize.height) operation:NSCompositingOperationCopy fraction:1.0];
    [newImage unlockFocus];

    return newImage;
}



@end
