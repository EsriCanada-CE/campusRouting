//
//  Site.h
//  
//
//  Created by admin on 12-10-11.
//  Copyright (c) 2012 Esri Canada. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ArcGIS/ArcGIS.h>
#import "Level.h"
#import "Route.h"
#import "BookStackLOCRange.h"

@interface Site : NSObject

@property (strong, nonatomic) NSMutableDictionary *rooms;
@property (strong, nonatomic) NSMutableDictionary *buildingNames;
@property (strong, nonatomic) NSMutableDictionary *planNames;
@property (strong, nonatomic) NSMutableArray *buildingCodes;
@property (strong, nonatomic) AGSGraphicsLayer *routelayer;

-(void) addRasterLookup:(AGSFeatureSet *)featureSet;
-(void) addRooms:(AGSFeatureSet *)objects;
-(void) removeAllPlans;
-(void) showPlan:(NSString*)name;
-(void) hidePlan:(NSString*)name;
-(id) initWithCredentials:(AGSCredential*)cred map:(AGSMapView*)mapView settings:(NSDictionary*)settings;
-(void) addBuildingNames:(AGSFeatureSet *)featureSet;
-(void) hideRoom:(NSString*) planId room:(NSString*)roomName;
-(void) showRoom:(NSString*)planId room:(NSString*)r withColour:(UIColor*)colour;
-(AGSEnvelope*) getEnvelope:(NSString*)planId room:(NSString*)roomName;
-(void) showStep:(NSNumber*) step;
-(NSInteger) addRoute:(AGSRouteTaskResult*)results;
-(AGSGraphic*) getRoomGraphic:(NSString*)planId room:(NSString*)roomName;
-(NSString*)getCurrentDirectionText:(NSString*)start endRoom:(NSString*)end;
-(void)addStacks:(AGSFeatureSet *)featureSet;
-(BookStackLOCRange*)findStack:(NSString*)callNumber withLibrary:(NSString*)library;
-(void)zoomToRooms;
-(void) resetRoute;


@end
