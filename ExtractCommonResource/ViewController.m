//
//  ViewController.m
//  ExtractCommonResource
//
//  Created by tanzou on 2018/6/28.
//  Copyright © 2018年 ND. All rights reserved.
//

#import "ViewController.h"

@interface ViewController()<NSTextDelegate>
//@property (weak) IBOutlet NSTextField *finishTipLabel;
@property (weak) IBOutlet NSTextField *finishTipLabel;

@property (weak) IBOutlet NSButton *clearButton;

@property (weak) IBOutlet NSTextField *filePathTextField;
@property (weak) IBOutlet NSTextField *prefixTextField;

@property (nonatomic, strong) NSMutableArray *all2XResources;
@property (nonatomic, strong) NSMutableArray *all3XResources;

@property (nonatomic, strong) NSMutableArray *sortOutResource;

@property (nonatomic, strong) NSMutableArray *dup2XResourceList;//按大小归类数组
@property (nonatomic, strong) NSMutableArray *dup3XResourceList;//按大小归类数组

@property (weak) IBOutlet NSProgressIndicator *progressView;

@property (nonatomic, assign) NSInteger all2XResourceCount;
@property (nonatomic, assign) NSInteger all3XResourceCount;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];
}

#pragma mark - click response
- (IBAction)searchDidClick:(id)sender {
    
    [self clearTempData];
    
    self.finishTipLabel.hidden = YES;
    self.progressView.hidden = NO;
    [self.progressView setUsesThreadedAnimation:YES];
    NSButton *button = (NSButton *)sender;
    button.title = @"扫描中";
    button.enabled = NO;
    self.clearButton.enabled = NO;
    
    [self loadResource];
    
    [self beginSortResource];
    
    self.sortOutResource = [self beginSortOutResource];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self createXLSFile:[NSArray arrayWithArray:self.sortOutResource]];
        button.title = @"扫描";
        button.enabled = YES;
        self.clearButton.enabled = YES;
        self.progressView.hidden = YES;
        self.finishTipLabel.hidden = NO;
    });
    
}
- (IBAction)clearDidClick:(id)sender {
    self.progressView.hidden = YES;
    [self clearTempData];
    self.prefixTextField.stringValue = @"";
    self.filePathTextField.stringValue = @"";
    self.finishTipLabel.hidden = YES;
}

- (void)clearTempData {
    [self.all2XResources removeAllObjects];
    [self.all3XResources removeAllObjects];
    [self.sortOutResource removeAllObjects];
    [self.dup3XResourceList removeAllObjects];
    [self.dup2XResourceList removeAllObjects];
    self.progressView.doubleValue = 0;
    self.finishTipLabel.stringValue = @"";
}

#pragma mark - loadResource

- (void)loadResource {
    NSLog(@"--------开始加载资源--------");
    
    NSString *path = self.filePathTextField.stringValue;
    [self showAllFileWithPath:path];
    self.all2XResourceCount = self.all2XResources.count;
    self.all3XResourceCount = self.all3XResources.count;
    
    NSLog(@"--------资源加载完毕--------");
    
}


- (void)showAllFileWithPath:(NSString *)path {
    
    
    if ([path containsString:@"commonResource"]) {
        return;
    }
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    BOOL isDir = NO;
    BOOL isExist = [fileManager fileExistsAtPath:path isDirectory:&isDir];
    
    if (isExist) {
        if(isDir) {
            NSArray * dirArray = [fileManager contentsOfDirectoryAtPath:path error:nil];
            NSString * subPath = nil;
            for (NSString * str in dirArray) {
                subPath  = [path stringByAppendingPathComponent:str];
                BOOL issubDir = NO;
                [fileManager fileExistsAtPath:subPath isDirectory:&issubDir];
                [self showAllFileWithPath:subPath];
            }
        } else {
            NSString *fileName = [[path componentsSeparatedByString:@"/"] lastObject];
            if ([fileName hasSuffix:@".png"] && [fileName containsString:@"3x"]) {//输出png
                [self.all3XResources addObject:@{@"path":path, @"imageName": fileName, @"size":@([NSData dataWithContentsOfFile:path].length)}];
            } else if ([fileName hasSuffix:@".png"]) {
                [self.all2XResources addObject:@{@"path":path, @"imageName": fileName, @"size":@([NSData dataWithContentsOfFile:path].length)}];
            }
        }
    } else {
        NSLog(@"文件不存在");
    }
}

#pragma mark - quick sort

- (void)beginSortResource {
    NSLog(@"--------开始排序--------");
    
    dispatch_group_t group = dispatch_group_create();
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(2);
    
    dispatch_group_async(group, queue, ^{
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        
        [self quickSort:self.all2XResources startIndex:0 endIndex:self.all2XResourceCount - 1];
        
        NSMutableArray *subList = [NSMutableArray array];
        [self.all2XResources addObject:@{@"size":@(-1000)}];
        [self.all2XResources enumerateObjectsUsingBlock:^(NSDictionary *obj, NSUInteger idx, BOOL * _Nonnull stop) {
            
            if (subList.count == 0 || [subList[0] objectForKey:@"size"] == [obj objectForKey:@"size"]) {
                [subList addObject:obj];
            } else {
                if (subList.count > 1) {
                    [self.dup2XResourceList addObject:[subList copy]];
                }
                [subList removeAllObjects];
                [subList addObject:obj];
            }
        }];
        dispatch_semaphore_signal(semaphore);
    });
    
    dispatch_group_async(group, queue, ^{
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        [self quickSort:self.all3XResources startIndex:0 endIndex:self.all3XResourceCount - 1];
        
        NSMutableArray *subList = [NSMutableArray array];
        [self.all3XResources addObject:@{@"size":@(-1000)}];
        [self.all3XResources enumerateObjectsUsingBlock:^(NSDictionary *obj, NSUInteger idx, BOOL * _Nonnull stop) {
            
            if (subList.count == 0 || [subList[0] objectForKey:@"size"] == [obj objectForKey:@"size"]) {
                [subList addObject:obj];
            } else {
                if (subList.count > 1) {
                    [self.dup3XResourceList addObject:[subList copy]];
                }
                [subList removeAllObjects];
                [subList addObject:obj];
            }
        }];
        dispatch_semaphore_signal(semaphore);
    });
    
    dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
    
    NSLog(@"--------结束排序--------");
}



- (NSInteger)partion:(NSMutableArray*)source lowPosition:(NSInteger)lowIndex HighPosition:(NSInteger)hightIndex {
    
    if (lowIndex == hightIndex) {
        return lowIndex;
    }
    
    NSDictionary *base = source[lowIndex];
    NSInteger i = lowIndex;
    
    for (NSInteger j = lowIndex; j <= hightIndex; j++) {
        if ([[source[j] objectForKey:@"size"] integerValue] < [[base objectForKey:@"size"] integerValue]) {
            i++;
            NSDictionary *temp = source[i];
            source[i] = source[j];
            source[j] = temp;
        }
    }
    
    NSDictionary *temp2 = source[i];
    source[i] = base;
    source[lowIndex] = temp2;
    
    return i;
    
}

- (void)quickSort:(NSMutableArray*)source startIndex:(NSInteger)startIndex endIndex:(NSInteger)endIndex {
    
    if (startIndex < endIndex) {
        NSInteger partPosition = [self partion:source lowPosition:startIndex HighPosition:endIndex];
        
        [self quickSort:source startIndex:startIndex endIndex:partPosition - 1];
        [self quickSort:source startIndex:partPosition + 1 endIndex:endIndex];
    }
}

#pragma mark - scan

- (NSMutableArray *)beginSortOutResource {
    NSLog(@"--------扫描资源--------");
    [self.progressView startAnimation:nil];
    
    NSMutableArray *finishResource = [NSMutableArray array];
    [finishResource addObjectsFromArray:[self begin2XSortOutResource]];
    [finishResource addObjectsFromArray:[self begin3XSortOutResource]];
    
    [self.progressView stopAnimation:nil];
    NSLog(@"--------扫描完毕--------");
    
    return finishResource;
}

- (NSMutableArray *)begin2XSortOutResource {
    
    dispatch_group_t group = dispatch_group_create();
    dispatch_semaphore_t semaphore = dispatch_semaphore_create((5));
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    
    NSMutableArray *finishResource = [NSMutableArray array];
    
    for (NSInteger i = 0; i < self.dup2XResourceList.count; i++) {
        NSMutableArray *equalM = [NSMutableArray array];
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        dispatch_group_async(group, queue, ^{
            
            NSMutableArray *tempArray = [NSMutableArray arrayWithArray:self.dup2XResourceList[i]];
            for (NSDictionary *dict1 in self.dup2XResourceList[i]) {
                
                NSData *data1 = [NSData dataWithContentsOfFile:[dict1 objectForKey:@"path"]];
                NSMutableArray *M = [NSMutableArray array];
                for (NSDictionary *dict2 in self.dup2XResourceList[i]) {
                    
                    if (M.count != 0 && [dict1 objectForKey:@"size"] != [dict2 objectForKey:@"size"]) {//大小不一致 进入下次循环
                        break;
                    }
                    
                    NSData *data2 = [NSData dataWithContentsOfFile:[dict2 objectForKey:@"path"]];
                    if ([data1 isEqual:data2]) {
                        [M addObject:dict2];
                        [tempArray removeObject:dict2];
                    }
                }
                if (![equalM containsObject:M] && M.count > 1) {
                    @synchronized(self) {
                        [equalM addObject:M];
                    }
                }
                
                self.dup2XResourceList[i] = [NSMutableArray arrayWithArray:tempArray];
            }
            dispatch_semaphore_signal(semaphore);
            
            @synchronized(self) {
                [finishResource addObjectsFromArray:equalM];
            }
        });
    }
    
    dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
    
    return finishResource;
}

- (NSMutableArray *)begin3XSortOutResource {
    
    dispatch_group_t group = dispatch_group_create();
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(5);
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    
    NSMutableArray *finishResource = [NSMutableArray array];
    
    for (NSInteger i = 0; i < self.dup3XResourceList.count; i++) {
        NSMutableArray *equalM = [NSMutableArray array];
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        dispatch_group_async(group, queue, ^{
            
            NSMutableArray *tempArray = [NSMutableArray arrayWithArray:self.dup3XResourceList[i]];
            for (NSDictionary *dict1 in self.dup3XResourceList[i]) {
                
                NSData *data1 = [NSData dataWithContentsOfFile:[dict1 objectForKey:@"path"]];
                NSMutableArray *M = [NSMutableArray array];
                for (NSDictionary *dict2 in self.dup3XResourceList[i]) {
                    
                    if (M.count != 0 && [dict1 objectForKey:@"size"] != [dict2 objectForKey:@"size"]) {//大小不一致 进入下次循环
                        break;
                    }
                    
                    NSData *data2 = [NSData dataWithContentsOfFile:[dict2 objectForKey:@"path"]];
                    if ([data1 isEqual:data2]) {
                        [M addObject:dict2];
                        [tempArray removeObject:dict2];
                    }
                }
                if (![equalM containsObject:M] && M.count > 1) {
                    @synchronized(self) {
                        [equalM addObject:M];
                    }
                }
                
                self.dup2XResourceList[i] = [NSMutableArray arrayWithArray:tempArray];
            }
            dispatch_semaphore_signal(semaphore);
            
            @synchronized(self) {
                [finishResource addObjectsFromArray:equalM];
            }
        });
        
    }
    
    dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
    
    return finishResource;
}

- (BOOL)isCorrespondingImage:(NSDictionary *)dict2X array3X:(NSArray *)array3X {//判断是否是 2x=>3x
    BOOL result = NO;
    NSString * imageName = nil;
    
    for (NSDictionary *dict3X in array3X) {
        imageName = [[dict3X objectForKey:@"imageName"] componentsSeparatedByString:@"@3x.png"][0];
        result = [[dict2X objectForKey:@"imageName"] containsObject:imageName];
        break;
    }
    
    return result;
}


#pragma mark - excel

- (void)createXLSFile:(NSArray *)array {
    
    NSLog(@"--------复制资源、创建excel--------");
    
    NSFileManager *fileManager = [[NSFileManager alloc]init];
    
    NSString * DirectoryPath = [NSString stringWithFormat:@"%@/commonResource",self.filePathTextField.stringValue];
    
    BOOL isExist = [fileManager fileExistsAtPath:DirectoryPath];
    if (isExist) {
        [fileManager removeItemAtPath:DirectoryPath error:nil];
    }
    
    NSError * error = nil;
    
    BOOL success = [fileManager createDirectoryAtPath:DirectoryPath withIntermediateDirectories:NO attributes:nil error:&error];
    
    if (!success) {
        self.finishTipLabel.stringValue = @"请添加扫描文件夹";
        NSLog(@"创建文件夹失败");
        return;
    }
    self.finishTipLabel.stringValue = @"扫描完成";
    NSLog(@"创建成功");
    
    NSMutableArray  *xlsDataMuArr = [[NSMutableArray alloc] init];
    // 第一行内容
    [xlsDataMuArr addObject:@"path"];
    [xlsDataMuArr addObject:@"componentFolder"];
    [xlsDataMuArr addObject:@"oldImageName"];
    [xlsDataMuArr addObject:@"newImageName"];
    
    NSString *path = nil;
    NSString *oldImageName = nil;
    NSString *bundle = nil;
    NSString *newImageName = nil;
    NSArray *parts = [NSArray array];
    NSMutableArray *allNameArray = [NSMutableArray array];
    NSMutableArray *allNameArraya = [NSMutableArray array];
    BOOL tag;
    NSString *saveTempImageName = nil;
    NSMutableArray *sameImageList = [NSMutableArray array];
    BOOL isError = NO;
    
    for (int i = 0; i < array.count; i ++) {
        tag = NO;
        NSArray *jM = array[i];
        
        [sameImageList removeAllObjects];
        if ([[((NSDictionary *)jM[0]) objectForKey:@"imageName"] containsString:@"@3x"]) {
            for (NSDictionary *dict in jM) {
                [sameImageList addObject:[dict objectForKey:@"imageName"]];
            }
        }
        
        for (NSInteger j = 0; j < jM.count; j++) {
            
            path = [((NSDictionary *)jM[j]) objectForKey:@"path"];
            oldImageName = [((NSDictionary *)jM[j]) objectForKey:@"imageName"];
            parts = [path componentsSeparatedByString:@"/"];
            bundle = parts[parts.count - 2];
            
            [xlsDataMuArr addObject:path];
            [xlsDataMuArr addObject:bundle];
            [xlsDataMuArr addObject:oldImageName];
            
            if (![oldImageName containsString:@"@2x.png"] && ![oldImageName containsString:@"@3x.png"]) {
                oldImageName = [[oldImageName substringToIndex:oldImageName.length - 4] stringByAppendingString:@"@2x.png"];
            }
            
            if (![oldImageName hasSuffix:@"@2x.png"] && ![oldImageName hasSuffix:@"@3x.png"]) {
                saveTempImageName = [NSString stringWithFormat:@"Path:%@,资源后缀名有误（请使用@2x.png或@3x.png命名资源），请修改后重试",path];
                self.finishTipLabel.stringValue = saveTempImageName;
            }
            
            if ([oldImageName hasSuffix:@"@2x.png"] && j == 0) {
                saveTempImageName = oldImageName;
                [allNameArraya addObject:[[oldImageName substringToIndex:oldImageName.length - 7] stringByAppendingString:@"@3x.png"]];
            }
           
            if ([oldImageName hasSuffix:@"@3x.png"] && j == 0) {
                saveTempImageName = @"该资源与其对应的其他2x、3X图大小不一致，请根据oldImageName查找对比2x图手动剔除，或补充相应的2x、3x图";
                for (NSInteger i = 0; i < sameImageList.count; i++) {
                    if ([allNameArraya containsObject:sameImageList[i]]) {
                        saveTempImageName = sameImageList[i];
                        break;
                    }
                }
            }
            
            newImageName = [NSString stringWithFormat:@"%@%@%@",self.prefixTextField.stringValue, [self.prefixTextField.stringValue isEqualToString:@""] ? @"" : @"_", saveTempImageName];
        
            newImageName = [newImageName lowercaseString];
            [xlsDataMuArr addObject:newImageName];
            
            
            //        移动资源
            if (j == 0 && ![oldImageName hasSuffix:@"@3x.png"]) {
                
                [fileManager copyItemAtPath:path toPath:[NSString stringWithFormat:@"%@/%@",DirectoryPath,newImageName] error:nil];
                [allNameArray addObject:[[oldImageName substringToIndex:oldImageName.length - 7] stringByAppendingString:@"@3x.png"]];
                tag = YES;
            } else if ([oldImageName hasSuffix:@"@3x.png"] && [allNameArray containsObject:oldImageName] && !tag) {
                [fileManager copyItemAtPath:path toPath:[NSString stringWithFormat:@"%@/%@",DirectoryPath,newImageName] error:nil];
                [allNameArray addObject:oldImageName];
                tag = YES;
            } else if (!tag && j == jM.count - 1) {
                if ([saveTempImageName containsString:@"该资源与其对应的其他2x、3X图大小不一致，请根据oldImageName"]) {
                    newImageName = [NSString stringWithFormat:@"%@_%@",newImageName, oldImageName];
                }
                [fileManager copyItemAtPath:path toPath:[NSString stringWithFormat:@"%@/%@",DirectoryPath,newImageName] error:nil];
                [allNameArray addObject:oldImageName];
                tag = YES;
                isError = YES;
            }
            
            
        }
        
        [xlsDataMuArr addObject:@"  "];
        [xlsDataMuArr addObject:@"  "];
        [xlsDataMuArr addObject:@"  "];
        [xlsDataMuArr addObject:@"  "];
        
    }
    NSString *fileContent = [xlsDataMuArr componentsJoinedByString:@"\t"];
    NSMutableString *muStr = [fileContent mutableCopy];
    
    NSMutableArray *subMuArr = [NSMutableArray array];
    for (int i = 0; i < muStr.length; i ++) {
        NSRange range = [muStr rangeOfString:@"\t" options:NSBackwardsSearch range:NSMakeRange(i, 1)];
        if (range.length == 1) {
            [subMuArr addObject:@(range.location)];
        }
    }
    
    for (NSUInteger i = 0; i < subMuArr.count; i ++) {
        
        if ( i > 0 && (i % 4 == 0) ) {
            [muStr replaceCharactersInRange:NSMakeRange([[subMuArr objectAtIndex:i-1] intValue], 1) withString:@"\n"];
        }
    }
    
    
    
    NSData *fileData = [muStr dataUsingEncoding:NSUTF16StringEncoding];
    
    NSString *filePath = [NSString stringWithFormat:@"%@/export.xls",self.filePathTextField.stringValue];
    NSLog(@"文件路径：\n%@",filePath);
    
    [fileManager createFileAtPath:filePath contents:fileData attributes:nil];
    
    //    完成后打开文件夹
    NSString *strCMD_MKDIR = [NSString stringWithFormat:@"open %@", DirectoryPath];
    system([strCMD_MKDIR UTF8String]);
    
    if (isError) {
        self.finishTipLabel.stringValue = @"扫描完成！存在未知3x图！请查看excel";
    }
    
    NSLog(@"--------完成--------");
}


#pragma mark - textDelegate

- (void)textDidChange:(NSNotification *)notification {
    [self.all2XResources removeAllObjects];
    [self.all3XResources removeAllObjects];
    [self.sortOutResource removeAllObjects];
    [self.dup3XResourceList removeAllObjects];
    [self.dup2XResourceList removeAllObjects];
}


#pragma mark - Lazy

- (NSMutableArray *)all2XResources {
    if (_all2XResources == nil) {
        _all2XResources = [NSMutableArray array];
    }
    return _all2XResources;
}
- (NSMutableArray *)all3XResources {
    if (_all3XResources == nil) {
        _all3XResources = [NSMutableArray array];
    }
    return _all3XResources;
}

- (NSMutableArray *)sortOutResource {
    if (_sortOutResource == nil) {
        _sortOutResource = [NSMutableArray array];
    }
    return _sortOutResource;
}

- (NSMutableArray *)dup2XResourceList {
    if (_dup2XResourceList == nil) {
        _dup2XResourceList = [NSMutableArray array];
    }
    return _dup2XResourceList;
}
- (NSMutableArray *)dup3XResourceList {
    if (_dup3XResourceList == nil) {
        _dup3XResourceList = [NSMutableArray array];
    }
    return _dup3XResourceList;
}


@end
