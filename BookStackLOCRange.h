//
//  BookStackLOCRange.h
//  DalFind
//
//  Created by admin on 2013-11-27.
//  Copyright (c) 2013 Esri Canada. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <ArcGIS/ArcGIS.h>

@interface BookStackLOCRange : NSObject

@property (nonatomic, strong) NSString* one;
@property (nonatomic, strong) NSString* two;
@property (nonatomic, strong) NSString* three;
@property (nonatomic, strong) NSString* four;
@property (nonatomic, strong) NSString* oneE;
@property (nonatomic, strong) NSString* twoE;
@property (nonatomic, strong) NSString* threeE;
@property (nonatomic, strong) NSString* fourE;
@property (nonatomic, strong) AGSGraphic* graphic;
@property (nonatomic, strong) NSString* building;
@property (nonatomic, strong) NSString* planid;

-initWithStartRange:(NSString*)start EndRange:(NSString*)end building:(NSString*)building planid:(NSString*)planid graphic:(AGSGraphic*)g;
-(BOOL)inRange:(NSString*)callNumber;

@end
