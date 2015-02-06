//
//  BookStackLOCRange.m
//  DalFind
//
//  Created by admin on 2013-11-27.
//  Copyright (c) 2013 Esri Canada. All rights reserved.
//

#import "BookStackLOCRange.h"

@implementation BookStackLOCRange

-initWithStartRange:(NSString*)start EndRange:(NSString*)end building:(NSString*)building planid:(NSString*)planid graphic:(AGSGraphic*)g
{
    self.one = @"";
    self = [super init];
    self.graphic = g;
    NSArray* startCallNumberArray = [self splitCallNumber:start];
    NSArray* endCallNumberArray = [self splitCallNumber:end];
    self.one = [startCallNumberArray objectAtIndex:0];
    self.two = [startCallNumberArray objectAtIndex:1];
    self.three = [startCallNumberArray objectAtIndex:2];
    self.four = [startCallNumberArray objectAtIndex:3];
    self.oneE = [endCallNumberArray objectAtIndex:0];
    self.twoE = [endCallNumberArray objectAtIndex:1];
    self.threeE = [endCallNumberArray objectAtIndex:2];
    self.fourE = [endCallNumberArray objectAtIndex:3];
    self.building = building;
    self.planid = planid;
    return self;
}


-(BOOL)inLocalRange:(NSString *)test lower:(NSString*)low upper:(NSString*)up mode:(NSString*)mode
{
    if ([test isEqualToString:@""]) return YES;
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    NSNumber *numberTest = ([formatter numberFromString:test]);
    
    BOOL lowerTest;
    BOOL upperTest;
    if (numberTest == nil){
        lowerTest = ((NSComparisonResult)[low compare: test] == NSOrderedAscending || (NSComparisonResult)[test compare: low] == NSOrderedSame);
        upperTest = ((NSComparisonResult)[up compare: test] == NSOrderedDescending || (NSComparisonResult)[test compare: up] == NSOrderedSame);
    }
    else{
        NSNumber *lowerNumber = ([formatter numberFromString:low]);
        NSNumber *upperNumber = ([formatter numberFromString:up]);
        
        lowerTest = [numberTest doubleValue] >= [lowerNumber doubleValue];
        upperTest = [numberTest doubleValue] <= [upperNumber doubleValue];;
    }
    if ([mode isEqualToString:@"both"] || [mode isEqualToString:@"lowerupper"]) return (lowerTest && upperTest);
    else if ([mode isEqualToString:@"lower"]) return lowerTest;
    else return upperTest;
}


-(NSString*)matchConfirmed:(NSString *)test lower:(NSString*)low upper:(NSString*)up mode:(NSString*)mode;
{
    if ([mode isEqualToString:@"both"])
    {
        NSMutableString *m = [[NSMutableString alloc]init];
        if ([test isEqualToString:low]){
            [m appendString:@"lower"];
            
        }
        if ([test isEqualToString:up]){
            [m appendString:@"upper"];
        }
        if (![m isEqualToString:@""])
        {
            return m;
        }
    }
    else if ([mode isEqualToString:@"lower"] && ![test isEqualToString:low]){
        return @"both";
    }
    else if ([mode isEqualToString:@"upper"] && ![test isEqualToString:up]){
        return @"both";
    }
    else if ([mode isEqualToString:@"lowerupper"] && ![test isEqualToString:low] && ![test isEqualToString:up]) return @"both";
    // if mode is initially set to upper or lower
    return mode;
}


-(BOOL)inRange:(NSString*)callNumber
{
    NSArray* callNumberArray = [self splitCallNumber:callNumber];
    NSString* oneL = [callNumberArray objectAtIndex:0];
    NSString* twoL = [callNumberArray objectAtIndex:1];
    NSString* threeL = [callNumberArray objectAtIndex:2];
    NSString* fourL = [callNumberArray objectAtIndex:3];
    
    NSString *mode = @"both";
    
    if ([self inLocalRange:oneL lower:self.one upper:self.oneE mode:mode]){
        if (!(([self.one isEqualToString:@"OVERSIZE"])||([self.one isEqualToString:@"NO_SHEET"])||([self.one isEqualToString:@"nd"])))
        {
            mode = [self matchConfirmed:oneL lower:self.one upper:self.oneE mode:mode];
            if ([self.two isEqualToString:@""] || [mode isEqualToString:@"both"]){
                return YES;
            }
            else if ([self inLocalRange:twoL lower:self.two upper:self.twoE mode:mode]){
                mode = [self matchConfirmed:twoL lower:self.two upper:self.twoE mode:mode];
                if ([self.three isEqualToString:@""] || [mode isEqualToString:@"both"]){
                    return YES;
                }
                else if([self inLocalRange:threeL lower:self.three upper:self.threeE mode:mode]){
                    mode = [self matchConfirmed:threeL lower:self.two upper:self.threeE mode:mode];
                    if ([self.four isEqualToString:@""] || [mode isEqualToString:@"both"]){
                        return YES;
                    }
                    else if ([self inLocalRange:fourL lower:self.four upper:self.fourE mode:mode]){
                        return YES; 
                    }
                }
            }
        }
    }
    return NO;
}

-(NSArray*)splitCallNumber:(NSString*)callNumber
{
    //remove whitespaces
    callNumber = [callNumber stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    NSArray *output = [[NSArray alloc] init];
    
    NSString *exp = @"^([a-z|A-Z]*)(\\d*\\.*\\d*)([a-z|A-Z]*)(\\d*)(\\w*)";
    NSError *error;
    
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:exp options:0 error:&error];
    
    if (error) {
        NSLog(@"%@", error);
    } else {
        NSTextCheckingResult* result = [regex firstMatchInString:callNumber options:0 range:NSMakeRange(0, [callNumber length])];
        NSString* one = @"";
        NSString* two = @"";
        NSString* three = @"";
        NSString* four = @"";
        
        if (result) {
            NSLog(@"%d", [result numberOfRanges]);
            for (int i = 0; i < [result numberOfRanges]; i++)
            {
                if (i == 0 && !NSEqualRanges([result rangeAtIndex:1], NSMakeRange(NSNotFound, 0)))
                    one = [callNumber substringWithRange:[result rangeAtIndex:1]];
                else if (i == 1 && !NSEqualRanges([result rangeAtIndex:2], NSMakeRange(NSNotFound, 0)))
                    two = [callNumber substringWithRange:[result rangeAtIndex:2]];
                else if (i == 2 && !NSEqualRanges([result rangeAtIndex:3], NSMakeRange(NSNotFound, 0)))
                    three = [callNumber substringWithRange:[result rangeAtIndex:3]];
                else if (i == 3 && !NSEqualRanges([result rangeAtIndex:4], NSMakeRange(NSNotFound, 0))){
                    //if the fourth section isn't an empty string append "."
                    if (![[callNumber substringWithRange:[result rangeAtIndex:4]] isEqualToString:@""])
                    {
                        four = [@"." stringByAppendingString:[callNumber substringWithRange:[result rangeAtIndex:4]] ];
                    }
                }
            }
        }
        output = [[NSArray alloc] initWithObjects:one, two, three, four, nil];
    }
    return output;
}


@end
