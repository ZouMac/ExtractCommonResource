//
//  main.m
//  NSImageCompare
//
//  Created by Zou Tan on 2019/3/26.
//  Copyright © 2019 ND. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UIImage+compare.h"

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        
        NSImage *ima = [[NSImage alloc] initWithContentsOfFile:@"/Users/zoutan/Downloads/ExtractCommonResource-master/NSImageCompare/a.png"];
        NSImage *imb = [[NSImage alloc] initWithContentsOfFile:@"/Users/zoutan/Downloads/ExtractCommonResource-master/NSImageCompare/a2.png"];
        float a = [ima sameWithImage:imb];
        NSLog(@"aaa");
        
        // insert code here...
        NSLog(@"Hello, World!");
    }
    return 0;
}
