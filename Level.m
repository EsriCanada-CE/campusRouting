//
//  Level.m
//  
//
//  Created by admin on 12-10-11.
//  Copyright (c) 2012 Esri Canada. All rights reserved.
//

#import "Level.h"

@implementation Level

-(void) hide:(AGSGraphicsLayer*) layer
{
    for (Room *r in self.room)
    {
        [[self.room objectForKey:r] hide:layer];
    }
}

-(void) show:(AGSGraphicsLayer*) layer
{
    for (Room *r in self.room)
    {
        [[self.room objectForKey:r] show:layer];
    }
}

-(void) addRoom:(Room*)newRoom
{
    [self.room setObject:newRoom forKey:newRoom.number];
}

-(Room*) getRoom:(NSString*)roomName
{
    return [self.room objectForKey:roomName];
}


-initWithPlanId:(NSString*)plan
{
    self = [super init];
    self.room = [[NSMutableDictionary alloc]init];
    self.planId = plan;
    return self;
}

@end
