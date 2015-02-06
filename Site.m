//
//  Site.m
//  
//
//  Created by admin on 12-10-11.
//  Copyright (c) 2012 Esri Canada. All rights reserved.
//

#import "Site.h"


@interface Site()
@property (strong, nonatomic) NSMutableOrderedSet * visiblePlans;
@property (strong, nonatomic) NSMutableDictionary *lookupPlanId;
@property (strong, nonatomic) NSMutableDictionary *plans;
@property (strong, nonatomic) AGSMosaicRule *rule;
@property (strong, nonatomic) NSMutableArray *rasterIds;
@property (strong, nonatomic) AGSImageServiceLayer *planImageServiceLayer;
@property (strong, nonatomic) AGSDynamicMapServiceLayer *planMapServiceLayer;
@property (strong, nonatomic) AGSGraphicsLayer *roomlayer;
@property (strong, nonatomic) AGSGraphicsLayer *roomNamelayer;
@property (strong, nonatomic) Route *path;
@property (strong, nonatomic) NSMutableDictionary *levels;
@property (strong, nonatomic) AGSMapView *map;
@property (strong, nonatomic) NSString *planLayerType;
@property (strong, nonatomic) NSMutableDictionary *visitedBuildings;
@property (strong, nonatomic) NSMutableArray *libraryStacks;
@property (strong, nonatomic) NSString *delimiter;
@property NSInteger lastStep;
@property NSInteger startLayerRange;
@property NSInteger endLayerRange;
@property BOOL accessible;
@end



@implementation Site



NSInteger customSort(id s1, id s2, void*context);


-(void)zoomTo:(AGSMutableEnvelope *)env
{
    [env expandByFactor:10];
    [self.map zoomToEnvelope:env animated:YES];
}

-(id)initWithCredentials:(AGSCredential*)cred map:(AGSMapView*)mapView settings:(NSDictionary*)settings
{
    self = [super init];
    self.map = mapView;
    //add your local tile package here:
    //AGSLocalTiledLayer* tiledLayer = [AGSLocalTiledLayer localTiledLayerWithName:@"FILL IN NAME OF FILE"];
    self.delimiter = [settings objectForKey:@"delimiter"];
    self.lastStep = 0;
    self.planLayerType = [settings objectForKey:@"indoorPlans"];
    self.visitedBuildings = [[NSMutableDictionary alloc] init];
    self.lookupPlanId = [[NSMutableDictionary alloc] init];
    self.buildingNames = [[NSMutableDictionary alloc] init];
    self.planNames = [[NSMutableDictionary alloc] init];
    self.buildingCodes = [[NSMutableArray alloc] init];
    self.plans = [[NSMutableDictionary alloc] init];
    self.levels = [[NSMutableDictionary alloc] init];
    self.path = [[Route alloc] init];
    self.roomNamelayer = [AGSGraphicsLayer graphicsLayer];
    self.roomlayer = [AGSGraphicsLayer graphicsLayer];
    self.routelayer = [AGSGraphicsLayer graphicsLayer];
    self.rooms = [[NSMutableDictionary alloc] init];
    self.plans = [[NSMutableDictionary alloc] init];
    self.libraryStacks = [[NSMutableArray alloc] init];
        [self.roomNamelayer setMinScale:1200];
    
    
    if ([settings objectForKey:@"startLayerRange"])
    {
        self.startLayerRange = [[settings objectForKey:@"startLayerRange"] integerValue];
        self.endLayerRange = [[settings objectForKey:@"endLayerRange"] integerValue];
    }
    else
    {
        self.startLayerRange = 0;
        self.endLayerRange = 0;
    }
    
       self.visiblePlans = [[NSMutableOrderedSet alloc] init];
    if ([self.planLayerType isEqualToString:@"mapServiceLayer"])
    {
        NSURL* mapServiceUrl = [NSURL URLWithString: [settings objectForKey:@"mapService"]];
        self.planMapServiceLayer = [AGSDynamicMapServiceLayer dynamicMapServiceLayerWithURL:mapServiceUrl credential:cred];
        [self.map addMapLayer:self.planMapServiceLayer withName:@"buildings"];
        
        [self updateLayerDefinition];
    }
    else if ([self.planLayerType isEqualToString:@"imageServiceLayer"])
    {
        NSURL* imageurl = [NSURL URLWithString: [settings objectForKey:@"planService"]];
        self.planImageServiceLayer = [AGSImageServiceLayer imageServiceLayerWithURL:imageurl credential:cred];
        self.rule = [[AGSMosaicRule alloc] init];
        self.rule.method = AGSMosaicMethodLockRaster;
        [self.visiblePlans addObject:[NSNumber numberWithInt:0]];
        self.rule.lockRasterIds = [self.visiblePlans array];
        self.rule.operation = AGSMosaicOperationTypeFirst;
        self.planImageServiceLayer.mosaicRule = self.rule;
        [self.map addMapLayer:self.planImageServiceLayer withName:@"buildings"];
    }
    else{
        AGSTiledMapServiceLayer* basemap = [AGSTiledMapServiceLayer tiledMapServiceLayerWithURL:[NSURL URLWithString:[settings objectForKey:@"topo"]]];
        //basemap.renderNativeResolution = YES;
        [self.map insertMapLayer:basemap withName:@"topo" atIndex:0];
        NSURL* url = [NSURL URLWithString: [settings objectForKey:@"mapService"]];
        AGSDynamicMapServiceLayer* mapLayer = [AGSDynamicMapServiceLayer dynamicMapServiceLayerWithURL:url credential:cred];
        [self.map addMapLayer:mapLayer withName:@"Symbols"];
    }
    
    NSURL* mapService = [NSURL URLWithString: [settings objectForKey:@"mapService"]];
    self.accessible = [[settings objectForKey:@"accessible"] boolValue];
    
    NSError *error = nil;
    AGSMapServiceInfo *serviceInfo = [[AGSMapServiceInfo alloc] initWithURL:mapService credential:cred error:&error];
    AGSEnvelope* envelope = [serviceInfo initialEnvelope];
    AGSMutableEnvelope *en = [envelope mutableCopy];
    [en expandByFactor:0.7];
    [self.map zoomToEnvelope:en animated:YES];

   
    [self.map addMapLayer:self.roomlayer withName:@"rooms"];
    [self.map addMapLayer:self.routelayer withName:@"route"];
    [self.map addMapLayer:self.roomNamelayer withName:@"roomNames"];
    return self;
}


-(Room*) getRoom:(NSString*)planId room:(NSString*)roomName
{
    Level *level = [self.levels objectForKey:planId];
    Room *r =  [level getRoom:roomName];
    return r;
}


-(AGSGraphic*) getRoomGraphic:(NSString*)planId room:(NSString*)roomName
{
    Level *level = [self.levels objectForKey:planId];
    [level getRoom:roomName];
    Room *r =  [level getRoom:roomName];
    return r.graphic;
}

-(void)removeBuildingPlans:(NSString*)building name:(NSString*)name
{
    NSArray *plans = [self.visitedBuildings objectForKey:building];
    if ([plans count] > 0)
    {
        for (NSString *plan in plans)
        {
            [self.visiblePlans removeObject:plan];
        }
        NSMutableArray *plansArray = [[NSMutableArray alloc]init];
        [plansArray addObject:name];
        [self.visitedBuildings setObject:plansArray forKey:building];
    }
    else{
        [[self.visitedBuildings objectForKey: building] addObject:name];
    }
}


-(void) showPlan:(NSString*)name
{
    
    if ([self.planLayerType isEqualToString:@"mapServiceLayer"])
    {
        //if we are using a mapservicelayer, remove plans that are in the same building (solves overlap)
        
        for (NSString* code in self.buildingCodes)
        {
            if ([name rangeOfString:code options:NSCaseInsensitiveSearch].location != NSNotFound){
                if ([name rangeOfString:@"elevator" options:NSCaseInsensitiveSearch].location == NSNotFound && [name rangeOfString:@"connecting" options:NSCaseInsensitiveSearch].location == NSNotFound)
                {
                    [self removeBuildingPlans:code name:name];
                }
                
            }
        }
    }
    
    Level* l = [self.levels objectForKey:name];
    NSDictionary *d  = l.room;
    for (NSString *key in d)
    {
        Room* r = [d objectForKey:key];
        AGSTextSymbol* label  = [[AGSTextSymbol alloc] initWithText:r.number color:[UIColor blackColor]];
        label.hAlignment = AGSTextSymbolHAlignmentCenter;
        label.fontSize = 10;
        if (!r.visible)
        {
            r.graphic.symbol = label;
        }
        [r show:self.roomNamelayer];
    }
    
    if ([self.planLayerType isEqualToString:@"imageServiceLayer"])
    {
        NSString *rasterId = [self.lookupPlanId objectForKey:name];
        [self.visiblePlans addObject:[NSNumber numberWithInt:[rasterId integerValue]]];
        [self updateMosaicRule];
    }
    else if ([self.planLayerType isEqualToString:@"mapServiceLayer"])
    {
        [self.visiblePlans addObject:name];
        [self updateLayerDefinition];
    }
}



-(NSString*)createDefinitionQuery:(NSString*)attributeName
{
    NSString* queryString = @"";
    for (NSString* planid in self.visiblePlans)
    {
        if ([self.visiblePlans indexOfObject:planid] == 0)
        {
            queryString = [NSString stringWithFormat:@"%@='%@'", attributeName, planid];
        }
        else
        {
            queryString = [NSString stringWithFormat:@"%@ OR %@='%@'", queryString, attributeName, planid];
        }
    }
    if ([queryString isEqualToString:@""])
    {
        queryString = @"1 = 2";
        
    }
    return queryString;
}

-(NSString*)getCurrentDirectionText:(NSString*)start endRoom:(NSString*)end
{
    NSString* out =  self.path.currentDirectionGraphic.text;
    if (self.path.currentDirectionGraphic.directionsStrings != nil){
        AGSNADirectionsString* planid = self.path.currentDirectionGraphic.directionsStrings[0];
        
        NSString* description = [self.planNames objectForKey:planid.value];
        if (description != nil){
            out = [out stringByReplacingOccurrencesOfString:planid.value withString:description];
        }
    }
    out = [out stringByReplacingOccurrencesOfString:@"Location 1" withString:start];
    out = [out stringByReplacingOccurrencesOfString:@", on the right" withString:@""];
    out = [out stringByReplacingOccurrencesOfString:@", on the left" withString:@""];
    out = [out stringByReplacingOccurrencesOfString:@"Go and go" withString:@"Go"];
    out = [out stringByReplacingOccurrencesOfString:@"stair" withString:@"stairs"];
    out = [out stringByReplacingOccurrencesOfString:@"Campus Map" withString:@"pathway"];
    out = [out stringByReplacingOccurrencesOfString:@"stairss" withString:@"stairs"];
    return out;
}


-(void) hidePlan:(NSString*)name
{
    Level* l = [self.levels objectForKey:name];
    [l hide:self.roomNamelayer];
    [self.roomNamelayer refresh];
    if ([self.planLayerType isEqualToString:@"imageServiceLayer"])
    {
        NSString *rasterId = [self.lookupPlanId objectForKey:name];
        [self.visiblePlans removeObject:[NSNumber numberWithInt:[rasterId integerValue]]];
        self.rule.lockRasterIds = [self.visiblePlans array];
        self.planImageServiceLayer.mosaicRule = self.rule;
    }
    else if ([self.planLayerType isEqualToString:@"mapServiceLayer"])
    {
        [self.visiblePlans removeObject:name];
        [self updateLayerDefinition];
    }
}


-(void) updateMosaicRule
{
    self.rule.lockRasterIds = [self.visiblePlans array];
    self.planImageServiceLayer.mosaicRule = self.rule;
}

-(void) updateLayerDefinition
{
    NSMutableArray *layerDefs = [[NSMutableArray alloc]init];
    for (int i = self.startLayerRange; i <= self.endLayerRange; i++)
    {
        NSString* defString = [self createDefinitionQuery:@"planid"];
        AGSLayerDefinition* layerDefOutline = [AGSLayerDefinition layerDefinitionWithLayerId:i definition:defString];
        [layerDefs addObject:layerDefOutline];
        
    }
    self.planMapServiceLayer.layerDefinitions = layerDefs;
}


-(void) removeAllPlans
{
    [self.visiblePlans removeAllObjects];
    if ([self.planLayerType isEqualToString:@"imageServiceLayer"])
    {
        [self.visiblePlans addObject:[NSNumber numberWithInt:0]];
        [self updateMosaicRule];
    }
    else if ([self.planLayerType isEqualToString:@"mapServiceLayer"])
    {
        [self updateLayerDefinition];
    }
}


-(void) resetRoute
{
    self.lastStep = 0;
    [self.routelayer removeAllGraphics];
    self.path = [[Route alloc] init];
    [self removeAllPlans];
}


//used for naming convention of pngs specific to Waterloo campus digitizing
-(NSString*)getRasterLookupTable:(NSString *)rasterCode
{
    NSError *error;
    NSRegularExpression* exp = [NSRegularExpression regularExpressionWithPattern:@"([0-9]*)([A-Z0-9]*)(_0*)([1-9]*B*)(1*FLR)(_*)([A-Z]*)" options:0 error:&error];
    NSString *output;
    if (error) {
        NSLog(@"%@", error);
        output = @"error";
    } else {
        
        NSTextCheckingResult* result = [exp firstMatchInString:rasterCode options:0 range:NSMakeRange(0, [rasterCode length])];
        
        if (result) {
            
            NSRange groupTwo = [result rangeAtIndex:2];
            NSRange groupFour = [result rangeAtIndex:4];
            NSRange groupSeven = [result rangeAtIndex:7];
            
            NSArray *buildingCode;
            if ([[rasterCode substringWithRange:groupSeven] isEqualToString:@""])
            {
                buildingCode = [NSArray arrayWithObjects: [rasterCode substringWithRange:groupTwo], @" - ", [rasterCode substringWithRange:groupFour], nil];
            }
            else
            {
                buildingCode = [NSArray arrayWithObjects: [rasterCode substringWithRange:groupTwo], @" - MZ", nil];
            }
            
            output = [buildingCode componentsJoinedByString:@""];
            NSLog(@"%@", output);
        }
    }
    return output;
}


-(void)addRasterLookup:(AGSFeatureSet *)featureSet
{
    for (AGSGraphic *entry in featureSet.features)
    {
        NSDictionary *building = [entry allAttributes];
        NSString *objectid = [[building objectForKey:@"OBJECTID"] description];
        NSString *name = [building objectForKey:@"Name"];
        NSString *mapName = [self getRasterLookupTable:name];
        if (mapName)[self.lookupPlanId setObject:objectid forKey:mapName];
    }
}


-(void)populateBuildingCodes
{
    NSMutableArray *tempBuildings = [NSMutableArray arrayWithArray:[self.rooms allKeys]];
    NSArray *sortedBuilding = [tempBuildings sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    for (NSString *key in sortedBuilding)
    {
        [self.buildingCodes addObject:key];
        
        //sort the individual room numbers
        NSArray *tempRooms = [[self.rooms objectForKey:key]allObjects];
        NSArray *sortedRooms = [tempRooms sortedArrayUsingFunction:customSort context:NULL];
        [self.rooms setValue:sortedRooms forKey:key];
    }
}


-(void)addRoom:(Room*)room
{
    if ([self.levels objectForKey:room.planId]){}
    else
    {
        Level *level = [[Level alloc] initWithPlanId:room.planId];
        [self.levels setObject:level forKey:room.planId];
    }
    [[self.levels objectForKey:room.planId]addRoom:room];
}

-(void)addStacks:(AGSFeatureSet *)featureSet
{
    for (AGSGraphic *graphic in featureSet.features)
    {
        NSDictionary *stacks = [graphic allAttributes];
        NSString *planid = [stacks objectForKey:@"planid"];
        NSString *startCallNumber = [stacks objectForKey:@"fromstack"];
        NSString *endCallNumber = [stacks objectForKey:@"tostack"];
        NSString *building = [stacks objectForKey:@"building"];
        BookStackLOCRange* stack = [[BookStackLOCRange alloc]initWithStartRange:startCallNumber EndRange:endCallNumber building:building planid:planid graphic:graphic];
        [self.libraryStacks addObject:stack];
    }
}

- (AGSCompositeSymbol*)routeSymbol {
	AGSCompositeSymbol *cs = [AGSCompositeSymbol compositeSymbol];
	
	AGSSimpleLineSymbol *sls1 = [AGSSimpleLineSymbol simpleLineSymbol];
	sls1.color = [UIColor whiteColor];
	sls1.style = AGSSimpleLineSymbolStyleSolid;
	sls1.width = 8;
	[cs addSymbol:sls1];
    
    
	AGSSimpleLineSymbol *sls2 = [AGSSimpleLineSymbol simpleLineSymbol];
	sls2.color = [UIColor blueColor];
	sls2.style = AGSSimpleLineSymbolStyleSolid;
	sls2.width = 4;
	[cs addSymbol:sls2];
	
	return cs;
}

- (AGSCompositeSymbol*)stackSymbol {
    AGSCompositeSymbol *cs = [AGSCompositeSymbol compositeSymbol];
    
    AGSSimpleLineSymbol *sls1 = [AGSSimpleLineSymbol simpleLineSymbol];
    sls1.color = [UIColor whiteColor];
    sls1.style = AGSSimpleLineSymbolStyleSolid;
    sls1.width = 8;
    [cs addSymbol:sls1];
    AGSSimpleLineSymbol *sls2 = [AGSSimpleLineSymbol simpleLineSymbol];
    sls2.color = [UIColor redColor];
    sls2.style = AGSSimpleLineSymbolStyleSolid;
    sls2.width = 4;
    [cs addSymbol:sls2];
    
    return cs;
}


-(BookStackLOCRange *)findStack:(NSString*)callNumber withLibrary:(NSString*)library
{
    [self.roomlayer removeAllGraphics];
    for (BookStackLOCRange* stack in self.libraryStacks)
    {
        if ([stack inRange:callNumber] && [stack.building isEqualToString:library])
        {
            stack.graphic.symbol = [self stackSymbol];
            [self.roomlayer addGraphic:stack.graphic];
            AGSMutableEnvelope *env = [[stack.graphic.geometry envelope] mutableCopy];
            [env expandByFactor:14];
            [self.map zoomToEnvelope:env animated:YES];
            [self.visiblePlans addObject:stack.planid];
            [self updateLayerDefinition];
            [self.planMapServiceLayer refresh];
            return stack;
        }
    }
    return nil;
}


- (NSString *)getSubstring:(NSString *)value afterString:(NSString *)separator
{
    NSRange firstInstance = [value rangeOfString:separator];
    NSUInteger num = firstInstance.location + firstInstance.length;
    if (num > 2000){
        num = 1;
    }
    NSRange finalRange = NSMakeRange(num, 1);
    return [value substringWithRange:finalRange];
}


-(void) addRoom:(NSDictionary*)room toBuilding:(NSString*)building
{    
    if ([[self.rooms objectForKey:building] count] == 0)
    {
        [[self.rooms objectForKey:building] addObject:room];
    }
    else
    {
        [[self.rooms objectForKey:building] addObject:room];
    }
}


-(void)addRooms:(AGSFeatureSet *)featureSet
{
    for (AGSGraphic *graphic in featureSet.features) {
        NSDictionary *room = [graphic allAttributes];
        
        NSString *plan = [room objectForKey:@"planid"];
        //NSString *planNum = [self getSubstring:plan afterString:@" - "];
        //NSString *roomNum = [NSString stringWithFormat:@"%@ %@", planNum, [room objectForKey:@"name"]];
        NSString *roomNum = [NSString stringWithFormat:@"%@", [room objectForKey:@"name"]];
        
        
        BOOL accessibility = YES;
        if ([room objectForKey:@"accessible"] != nil)
        {
            if ([[room valueForKey:@"accessible"] doubleValue] == 0)
            {
                accessibility = NO;
            }
            else
            {
                accessibility = YES;
            }
        }
        
        NSArray *buildingCode = [plan componentsSeparatedByString: self.delimiter];
        NSString *building = [buildingCode objectAtIndex:0];
        
        Room *r = [[Room alloc]initWithNumber:roomNum building:building planId:plan graphic:graphic accessible:accessibility];
        [self addRoom:r];
        NSDictionary *roomEntry;
        if (self.accessible)
        {
            roomEntry = [NSDictionary dictionaryWithObjectsAndKeys:roomNum, @"name", graphic, @"graphic", plan, @"plan", [room valueForKey:@"accessible"], @"accessibility", nil];
        }
        else
        {
            roomEntry = [NSDictionary dictionaryWithObjectsAndKeys:roomNum, @"name", graphic, @"graphic", plan, @"plan", nil];
        }
        
        if (![self.rooms objectForKey:building]){
            NSMutableSet *rooms = [[NSMutableSet alloc] init];
            [self.rooms setObject:rooms forKey:building];
            NSMutableArray *plansArray = [[NSMutableArray alloc]init];
            [self.visitedBuildings setObject:plansArray forKey:building];
        }
        
        [self addRoom:roomEntry toBuilding:building];
        
        
        
        if (![self.plans objectForKey:plan]){
            [self.plans setObject:building forKey:plan];
        }
    }
    [self populateBuildingCodes];
}



NSInteger customSort(id s1, id s2, void*context)
{
    NSString* string1 = [s1 objectForKey:@"name"];
    NSString* string2 = [s2 objectForKey:@"name"];
    NSInteger roomNum1;
    NSInteger roomNum2;
    
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"(?![a-z])[0-9]+" options: 0 error:NULL];
    NSRange range = [regex rangeOfFirstMatchInString:string1 options:0 range:NSMakeRange(0, [string1 length])];
    
    //if range is found and it starts at the beginning of the string
    if (!NSEqualRanges(range, NSMakeRange(NSNotFound, 0)) && range.location == 0){
        NSString *result = [string1 substringWithRange:range];
        roomNum1 = [result integerValue];
    }
    else{
        return [string1 localizedCaseInsensitiveCompare:string2];
    }
    NSRange range2 = [regex rangeOfFirstMatchInString:string2 options:0 range:NSMakeRange(0, [string2 length])];
    if (!NSEqualRanges(range2, NSMakeRange(NSNotFound, 0)) && range2.location == 0){
        NSString *result = [string2 substringWithRange:range2];
        roomNum2 = [result integerValue];
        if (roomNum1 > roomNum2) return NSOrderedDescending;
        else if (roomNum1 < roomNum2) return NSOrderedAscending;
        else{
            return [string1 localizedCaseInsensitiveCompare:string2];
        }
    }
    else{
        return NSOrderedDescending;
    }
}


-(void)addBuildingNames:(AGSFeatureSet *)featureSet
{
    for (AGSGraphic *entry in featureSet.features) {
        NSDictionary *building = [entry allAttributes];
        NSString *buildingName = [building objectForKey:@"Name"];
        NSString *buildingCode = [building objectForKey:@"NameShort"];
        [self.buildingNames setObject:buildingName forKey:buildingCode];
    }
}


-(void) showRoom:(NSString*)planId room:(NSString*)roomName withColour:(UIColor*)colour
{
    Room *r = [self getRoom:planId room:roomName];
    AGSSimpleMarkerSymbol *markerSymbol = [[AGSSimpleMarkerSymbol alloc]init];
    markerSymbol.size = CGSizeMake(20,20);
    markerSymbol.style = AGSSimpleMarkerSymbolStyleCircle;
    markerSymbol.outline.color = [UIColor whiteColor];
    markerSymbol.outline.width = 3;
    markerSymbol.color = colour;
    r.graphic.symbol = markerSymbol;
    r.visible = YES;
    [self showPlan:planId];

    [r show:self.roomNamelayer];
    AGSEnvelope* env = [self getEnvelope:planId room:roomName];
    Room *rom = [self getRoom:planId room:roomName];
    AGSGeometry* geo = rom.graphic.geometry;
    AGSPoint *point = (AGSPoint*)geo;
    [self.map zoomToScale:800 animated:YES];
    [self.map centerAtPoint:point animated:YES];
    
    [self zoomTo:[env mutableCopy]];
}


-(void) hideRoom:(NSString*)planId room:(NSString*)roomName
{
    if (![planId isEqualToString:@""]){
        Room *r = [self getRoom:planId room:roomName];
        r.visible = NO;
        [self hidePlan: planId];
    }
}


-(AGSMutableEnvelope*) getEnvelope:(NSString*)planId room:(NSString*)roomName
{
    Room *r = [self getRoom:planId room:roomName];
    AGSEnvelope *env = (AGSEnvelope *)r.graphic.geometry.envelope;
    return [env mutableCopy];
}


-(void) showStep:(NSNumber*)step
{
    //draw the path
    NSString* plan = [self.path drawStep:self.routelayer atStep:step];
    
    
    AGSGraphic* route = [self.path getRouteGraphic:step];
    AGSPolyline* line = [route.geometry mutableCopy];
    AGSEnvelope* routeEnvelope = [line envelope];
    
    AGSEnvelope* env = [[line pointOnPath:0 atIndex:0] envelope] ;
    AGSEnvelope* env2 = [[line pointOnPath:0 atIndex:1] envelope] ;
    //if the line in not an elevator
    if (!([env isEqualToEnvelope:env2]) || !([step integerValue] == 0))
    {
        
         if (routeEnvelope.width < 20)
         {
             //[self.map zoomToScale:200 animated:YES];
             AGSPolyline* l = (AGSPolyline*)line;
             AGSPoint* destination = [l pointOnPath:0 atIndex:0];
             [[self routelayer] refresh];
             [self.map zoomToResolution:0.08 withCenterPoint:destination animated:YES];
             //[self.map centerAtPoint:destination animated:YES];
         }
         else{
             [self.map zoomToGeometry:route.geometry withPadding:300 animated:YES];
         }
    }
    
    if ([step integerValue] < self.lastStep && [step integerValue] != 0) //!=0 is there so we don't remove the first step from the map when the slider is at 0
    {
        for (int i = self.lastStep; i > [step integerValue]; i--)
        {
            NSString *planToHide = [self.path getPlanIdFromStep:[NSNumber numberWithInt:i]];
            [self hidePlan:planToHide];
        }
    }
    
    
    
    [self showPlan:plan];
    self.lastStep = [step integerValue];
}


-(NSInteger) addRoute:(AGSRouteTaskResult*)results
{
    self.path = [[Route alloc] initWithFeatures:results];
    [self.path drawRoute:self.routelayer];
    return self.path.numSteps;
}


#pragma mark AGSMapViewLayerDelegate
- (void)mapViewDidLoad:(AGSMapView *)mapView  {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(respondToEnvChange:)
    name:@"MapDidEndZooming" object:nil];
}


- (void)respondToEnvChange: (NSNotification*) notification {
}

-(void)zoomToRooms
{
    AGSGeometryEngine *geometryEngine = [AGSGeometryEngine defaultGeometryEngine];
    NSMutableArray *geoArray = [[NSMutableArray alloc]init];
    for (AGSGraphic* geo in self.path.routeResult.directions.graphics)
    {
        [geoArray addObject:geo.geometry];
    }
    AGSGeometry *geo = [geometryEngine unionGeometries:geoArray];
    [self.map zoomToGeometry:geo withPadding:80 animated:YES];
}


@end
