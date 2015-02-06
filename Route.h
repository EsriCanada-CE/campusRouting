//
//  Route.h
//  
//
//  Created by admin on 12-10-11.
//  Copyright (c) 2012 Esri Canada. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ArcGIS/ArcGIS.h>

@interface Route : NSObject

@property (strong, nonatomic) AGSRouteResult *routeResult;
@property (strong, nonatomic) AGSDirectionGraphic *currentDirectionGraphic;
@property (strong, nonatomic) AGSMutableEnvelope *envelope;

@property NSInteger numSteps;

-(NSString*)drawStep:(AGSGraphicsLayer*) layer atStep:(NSNumber*)step;
-initWithFeatures:(AGSRouteTaskResult*)results;
-(void)drawRoute:(AGSGraphicsLayer*)layer;
-(NSString*)getPlanIdFromStep:(NSNumber*)step;
-(AGSGraphic*)getRouteGraphic:(NSNumber*)step;
@end
