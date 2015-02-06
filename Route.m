//
//  Route.m
//
//  Created by admin on 12-10-11.
//  Copyright (c) 2012 Esri Canada. All rights reserved.
//

#import "Route.h"

@implementation Route

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


- (AGSCompositeSymbol*)stopSymbolWithNumber:(NSInteger)stopNumber {
	AGSCompositeSymbol *cs = [AGSCompositeSymbol compositeSymbol];
	
    // create outline
	AGSSimpleLineSymbol *sls = [AGSSimpleLineSymbol simpleLineSymbol];
	sls.color = [UIColor blackColor];
	sls.width = 2;
	sls.style = AGSSimpleLineSymbolStyleSolid;
	
    // create main circle
	AGSSimpleMarkerSymbol *sms = [AGSSimpleMarkerSymbol simpleMarkerSymbol];
	sms.color = [UIColor greenColor];
	sms.outline = sls;
	sms.size = CGSizeMake(20, 20);
	sms.style = AGSSimpleMarkerSymbolStyleCircle;
	[cs addSymbol:sms];
	
    // add number as a text symbol
	AGSTextSymbol *ts = [[AGSTextSymbol alloc] initWithText:[NSString stringWithFormat:@"%d", stopNumber]
															   color:[UIColor blackColor]];
	ts.vAlignment = AGSTextSymbolVAlignmentMiddle;
	ts.hAlignment = AGSTextSymbolHAlignmentCenter;
	ts.fontSize	= 0;
	ts.bold = YES;
	[cs addSymbol:ts];
	
	return cs;
}


- (AGSCompositeSymbol*)currentDirectionSymbol {
	AGSCompositeSymbol *cs = [AGSCompositeSymbol compositeSymbol];
	
	AGSSimpleLineSymbol *sls1 = [AGSSimpleLineSymbol simpleLineSymbol];
	sls1.color = [UIColor whiteColor];
	sls1.style = AGSSimpleLineSymbolStyleSolid;
	sls1.width = 8;
	[cs addSymbol:sls1];
	
	AGSSimpleLineSymbol *sls2 = [AGSSimpleLineSymbol simpleLineSymbol];
	sls2.color = [UIColor redColor];
	sls2.style = AGSSimpleLineSymbolStyleDash;
	sls2.width = 4;
	[cs addSymbol:sls2];
	
	return cs;	
}



-initWithFeatures:(AGSRouteTaskResult*)results
{
    self = [super init];
    self.routeResult = [results.routeResults lastObject];
	if (self.routeResult) {
		// symbolize the returned route graphic
		self.routeResult.routeGraphic.symbol = [self routeSymbol];
	}
    self.numSteps = [self.routeResult.directions.graphics count];
    return self;
}


-(NSString*) getPlanFromDirections:(NSString*)directions
{
    NSError *error = NULL;
    NSRegularExpression* exp = [NSRegularExpression regularExpressionWithPattern:@"(on\\s)(.*)" options:NSRegularExpressionCaseInsensitive error:&error];
    NSString *output = @"";
    if (error) {
        //NSLog(@"%@", error);
        output = @"error";
    } else {
        
        NSTextCheckingResult* result = [exp firstMatchInString:directions options:0 range:NSMakeRange(0, [directions length])];
        
        if (result) {
            
            NSRange group = [result rangeAtIndex:2];
            output = [directions substringWithRange:group];
        } 
    }
    return output;
}


-(NSString*)getPlanIdFromStep:(NSNumber*)step
{
    AGSDirectionGraphic *t = [self.routeResult.directions.graphics objectAtIndex:[step integerValue]];
    NSString *direction = [t attributeForKey:@"text"];
    NSString* planId = [self getPlanFromDirections:direction];
    return planId;
}


-(NSString*)drawStep:(AGSGraphicsLayer*) layer atStep:(NSNumber*)step
{
    // remove current direction graphic, so we can display next one
	if ([layer.graphics containsObject:self.currentDirectionGraphic]) {
		[layer removeGraphic:self.currentDirectionGraphic];
	}
	
    // get current direction and add it to the graphics layer
	AGSDirectionSet *directions = self.routeResult.directions;
	self.currentDirectionGraphic = [directions.graphics objectAtIndex:[step integerValue]];
	self.currentDirectionGraphic.symbol = [self currentDirectionSymbol];
	[layer addGraphic:self.currentDirectionGraphic];
    self.envelope = [self.currentDirectionGraphic.geometry.envelope mutableCopy];

    NSString* planId = [self getPlanIdFromStep:step];
	AGSMutableEnvelope *env = [self.currentDirectionGraphic.geometry.envelope mutableCopy];
    
    
    AGSPolyline* l = (AGSPolyline*)self.currentDirectionGraphic.geometry;
    
    AGSPoint* destination = [l pointOnPath:0 atIndex:0];
    AGSPoint* destination2 = [l pointOnPath:0 atIndex:1];
    
    //avoid drawing envelopes that are equal to each other
    if (!([[destination envelope] isEqualToEnvelope:[destination2 envelope]])){
        [env expandByFactor:15];
    }
	//[self.map zoomToEnvelope:env animated:YES];
	
    // determine if we need to disable a next/prev button
    
    return planId;
}

-(AGSGraphic*)getRouteGraphic:(NSString*) step
{
    AGSDirectionSet *directions = self.routeResult.directions;
	return [directions.graphics objectAtIndex:[step integerValue]];
}


-(void)drawRoute:(AGSGraphicsLayer*)layer
{
    // add the returned stops...it's possible these came back in a different order
    // because we specified findBestSequence
    if (self.routeResult) {
		// symbolize the returned route graphic
		[layer addGraphic:self.routeResult.routeGraphic];
    }
    for (AGSStopGraphic *sg in self.routeResult.stopGraphics) {
        
        // get the sequence from the attribetus
        NSInteger sequence = [[sg attributeForKey:@"Sequence"] integerValue];
        
        // create a composite symbol using the sequence number
        sg.symbol = [self stopSymbolWithNumber:sequence];
        
        // add the graphic
        [layer addGraphic:sg];
    }
}


@end
