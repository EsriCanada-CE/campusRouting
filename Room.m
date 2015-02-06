//
//  Room.m
//  
//
//  Created by admin on 12-10-11.
//  Copyright (c) 2012 Esri Canada. All rights reserved.
//

#import "Room.h"

@implementation Room


- initWithNumber:(NSString*)n building:(NSString*)b planId:(NSString*)p graphic:(AGSGraphic*)g accessible:(BOOL)a
{
    self = [super init];
    self.graphic = g;
    self.number = n;
    self.building = b;
    self.planId = p;
    self.accessible = a;
    self.visible = NO;
    self.markerSymbol = [[AGSSimpleMarkerSymbol alloc]init];
    self.markerSymbol.color = [UIColor redColor];
    self.markerSymbol.size = CGSizeMake(20,20);
    self.markerSymbol.style = AGSSimpleMarkerSymbolStyleCircle;
    self.markerSymbol.outline.color = [UIColor whiteColor];
    self.markerSymbol.outline.width = 3;
    AGSTextSymbol* label  = [[AGSTextSymbol alloc] initWithText:self.number color:[UIColor blackColor]];
    label.hAlignment = AGSTextSymbolHAlignmentCenter;
    label.fontSize = 0;
    self.graphic.symbol = label;
    return self;
}


-(void) hide:(AGSGraphicsLayer *)layer
{
    [layer removeGraphic:self.graphic];
}


-(void) show:(AGSGraphicsLayer *)layer
{
    BOOL found = NO;
    for (AGSGraphic* gr in[layer graphics])
    {
        if ([gr isEqual:self.graphic])
        {
            found = YES;
        }
    }
    if (!found)[layer addGraphic:self.graphic];
}


@end