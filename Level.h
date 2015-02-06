//
//  Level.h
//  
//
//  Created by admin on 12-10-11.
//  Copyright (c) 2012 Esri Canada. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ArcGIS/ArcGIS.h>
#import "Room.h"

@interface Level : NSObject

@property (nonatomic, strong) NSMutableDictionary *room;
@property (nonatomic, strong) NSString *rasterId;
@property (nonatomic, strong) NSString *planId;
-(Room*) getRoom:(NSString*)roomName;
-initWithPlanId:(NSString*)planId;
-(void) addRoom:(Room*)room;
-(void) hide:(AGSGraphicsLayer*) layer;
-(void) show:(AGSGraphicsLayer*) layer;
@end
