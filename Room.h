//
//  Room.h
//  
//
//  Created by admin on 12-10-11.
//  Copyright (c) 2012 Esri Canada. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ArcGIS/ArcGIS.h>

@interface Room : NSObject

@property (strong, nonatomic) NSString *number;
@property (strong, nonatomic) NSString *building;
@property (strong, nonatomic) NSString *planId;
@property (strong, nonatomic) AGSGraphic *graphic;
@property BOOL accessible;
@property BOOL visible;
@property (strong, nonatomic) AGSSimpleMarkerSymbol* markerSymbol;
-(void) hide:(AGSGraphicsLayer *)layer;
-(void) show:(AGSGraphicsLayer *)layer;
- initWithNumber:(NSString*)n building:(NSString*)b planId:(NSString*)p graphic:(AGSGraphic*)g accessible:(BOOL)a;
@end


