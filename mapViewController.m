
//  mapViewController.m
//  Waterloo Map
//
//  Created by admin on 12-08-14.
//  Copyright (c) 2012 Esri Canada. All rights reserved.

#import "mapViewController.h"
@interface mapViewController() {
    //ensure memory does not get deallocated for query tasks
    
}

@property (nonatomic, retain) AGSQueryTask *queryTask;
@property (strong, nonatomic) AGSRouteTask *routeTask;
@property (strong, nonatomic) NSString *startRoom;                      //room to start from
@property (strong, nonatomic) NSString *endRoom;                        //room at end
@property (strong, nonatomic) NSString *currentTextfield;               //whether the start or end field were selected last
@property (strong, nonatomic) ActivityAlertView *activityAlertView;     //routing alert
@property (strong, nonatomic) ActivityAlertView *loadingRoomAlertView;  //loading alert
@property (strong, nonatomic) NSString *currentCode;                    //last selected building code
@property (strong, nonatomic) AGSCredential *cred;                      //user credentials to access arcserver
@property (strong, nonatomic) NSString *startRaster;                    //planId of the starting room
@property (strong, nonatomic) NSString *endRaster;                      //planId of the ending room
@property (strong, nonatomic) Site *site;                               //object responsible for drawing dynamic components on map
@property (strong, nonatomic) NSNumber* routePointer;                   //tracks currently displayed route
@property (strong, nonatomic) AGSRouteTaskParameters *routeTaskParams;  //parameters dealing with the route task
@property (strong, nonatomic) NSDictionary *settings;                   //settings dictionary loaded from settings.plist
@property (strong, nonatomic) AGSQueryTask *planQt;                     //plan query task
@property (strong, nonatomic) AGSQueryTask *roomQt;                     //room query task
@property (strong, nonatomic) AGSQueryTask *imageQt;                    //image query task
@property (strong, nonatomic) AGSQueryTask *stackQt;                    //library query task
@property (strong, nonatomic) NSOperation *stackOp;                     //stack operation
@property (strong, nonatomic) NSOperation *imageOp;                     //image operation
@property (strong, nonatomic) NSOperation *roomOp;                      //room operation
@property (strong, nonatomic) NSOperation *planOp;                      //plan operation
@property (strong, nonatomic) AGSSketchGraphicsLayer* sketchLyr;        //used for sketching new geometry
@property (strong, nonatomic) AGSGraphic *startGraphic;                 //starting green symbol
@property (strong, nonatomic) AGSGraphic *endGraphic;                   //ending red symbol
@property (strong, nonatomic) NSString *token;                          //token generated from ArcGIS server using the supplied username and password
@property (strong, nonatomic) id data;                                  //copy of the bui=lding navigation list
@property (strong, nonatomic) BookStackLOCRange* stack;                 //chosen stack object
@property BOOL roomsLoaded;                                             //whether the room coordinates have been downloaded
@property BOOL reset;                                                   //keeps track of whether a reset is necessary
@property BOOL internetConnection;                                      //tracks internet connectivity
@property BOOL isCurled;                                                //tracks if the map is currently curles from tapping the settings button
@property BOOL stackNavigation;

@end


@implementation mapViewController

#pragma mark - View lifecycle



- (void)performRouting{
    
    [self.activityAlertView show];
    NSMutableArray *stops = [NSMutableArray array];
	[stops addObject:self.startGraphic];
    [stops addObject:self.endGraphic];
    [self.routeTaskParams setStopsWithFeatures:stops];
	self.routeTaskParams.outputGeometryPrecision = 0;
	self.routeTaskParams.outputGeometryPrecisionUnits = AGSUnitsMeters;
    self.routeTaskParams.directionsStyleName = @"NA Campus";
	self.routeTaskParams.returnRouteGraphics = YES;
	self.routeTaskParams.returnDirections = YES;
    self.routeTaskParams.outSpatialReference = self.map.spatialReference;
	self.routeTaskParams.ignoreInvalidLocations = YES;
    
    if (![[self.settings objectForKey:@"restriction"] isEqualToString:@"NA"])
    {
        NSString* restriction;
        if (![[self.settings objectForKey:@"accessible"]boolValue])
        {
            restriction = [self.settings objectForKey:@"restriction"];//@"PreferIndoor";
        }
        
        NSArray* restrictions = [[NSArray alloc] initWithObjects:restriction, @"anchor", nil];
        self.routeTaskParams.restrictionAttributeNames = restrictions;
    }

    NSDictionary* jsonDict = [self.routeTaskParams encodeToJSON];
    NSString* jsonString = [jsonDict ags_JSONRepresentation];
    
    
    if (self.stackNavigation)
    {
        jsonString = [jsonString stringByReplacingOccurrencesOfString:self.startRoom withString:@"Killam stacks"];
        NSArray* splitParams = [self splitJSON:jsonString];
        
        NSString *sfloor = [self getElevation:self.startRaster];
        NSString *efloor = [self getElevation:self.stack.planid];
        
        
        NSString* startFloor = [NSString stringWithFormat:@"%@%@%s", @"\"z\":", sfloor, ","];
        
        NSString* endFloor = [NSString stringWithFormat:@"%@%@%s", @"\"z\":", efloor, ","];
        
        jsonString = [NSString stringWithFormat:@"%@%@%@%@%@", [splitParams objectAtIndex:0], startFloor, [splitParams objectAtIndex:1], endFloor, [splitParams objectAtIndex:2]];
    }
    
    NSDictionary *done = [jsonString ags_JSONValue];
    NSString *urlString = [NSString stringWithFormat:@"%@/solve?f=json&token=%@", [self.settings objectForKey:@"networkService"], self.token];
    NSString* qs = [self addQueryStringToUrlString:urlString withDictionary:done];
    NSString *venuesQuery = [qs stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding];;
    [self performRequest:venuesQuery];
}


-(void)performRoutingRequest:(NSURLRequest*)parseRequest
{
    [NSURLConnection sendAsynchronousRequest:parseRequest
       queue:[NSOperationQueue mainQueue]
       completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
           if (data) {
               NSDictionary *responseDictionary = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
               [self.activityAlertView close];
               if ([responseDictionary valueForKey:@"error"]!=nil)
               {
                   [self updateDirectionsLabel:@"Route not found"];
               }
               else if (responseDictionary != nil)
               {
                   AGSRouteTaskResult* rt = [[AGSRouteTaskResult alloc] initWithJSON:responseDictionary];
                   self.reset = NO;
                   self.slider.hidden = NO;
                   self.slider.maximumValue = [self.site addRoute:rt] - 1;
                   self.slider.enabled = YES;
                   self.slider.value = 1;
                   self.directionsLabel.hidden = NO;
                   [self.site hidePlan:self.stack.planid];
                   [self drawRoute:[NSNumber numberWithInt:1]];
               }
               else{
                   [self performRoutingRequest:parseRequest];
               }
           }
       }];
}



-(void)performRequest:(NSString *)serviceURL
{
    //NSDictionary *fJson = @{@"f":@"json"};
    
    
    AGSJSONRequestOperation *jsonRequest = [[AGSJSONRequestOperation alloc] initWithURL:[NSURL URLWithString:serviceURL] queryParameters:nil];
    
    jsonRequest.credential = self.cred;
    
    jsonRequest.completionHandler = ^(NSDictionary *responseDictionary){
        [self.activityAlertView close];
        if (responseDictionary == nil  || [responseDictionary valueForKey:@"error"]!=nil)
        {
            [self updateDirectionsLabel:@"Route not found"];
        }
        else if (responseDictionary != nil)
        {
            AGSRouteTaskResult* rt = [[AGSRouteTaskResult alloc] initWithJSON:responseDictionary];
            self.reset = NO;
            self.slider.hidden = NO;
            self.slider.maximumValue = [self.site addRoute:rt] - 1;
            self.slider.enabled = YES;
            self.slider.value = 1;
            self.directionsLabel.hidden = NO;
            [self.site hidePlan:self.stack.planid];
            [self drawRoute:[NSNumber numberWithInt:1]];
        }

    };
    
    jsonRequest.errorHandler = ^(NSError *error){
        NSLog(@"Unable to access service info for : %@, %@ (%@)",serviceURL,error.localizedDescription,[NSNumber numberWithLong:error.code]);
    };
    
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    [queue setMaxConcurrentOperationCount:1];
    [queue addOperation:jsonRequest];
}



-(NSString*)getElevation:(NSString*)planid
{
    int floor;
    NSArray *ebuildingCode = [planid componentsSeparatedByString: [self.settings objectForKey:@"delimiter"]];
    if ([[ebuildingCode objectAtIndex:1] isEqualToString:@"B"]){
        floor = 0;
    }
    else
   {
       floor = [[ebuildingCode objectAtIndex:1]intValue];
   }
    return [@(floor*5)stringValue];
}


-(NSString*)urlEscapeString:(NSString *)unencodedString
{
    unencodedString = [unencodedString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    return unencodedString;
}


-(NSString*)addQueryStringToUrlString:(NSString *)urlString withDictionary:(NSDictionary *)dictionary
{
    NSMutableString *urlWithQuerystring = [[NSMutableString alloc] initWithString:urlString];
    
    for (id key in dictionary) {
        NSString* keyString = [key description];
        NSString* valueString = @"";
        if ([[dictionary objectForKey:key] isKindOfClass:[NSDictionary class]])
        {
            valueString = [[dictionary objectForKey:key] ags_JSONRepresentation];
        }
        else
        {
            valueString = [[dictionary objectForKey:key] description];
        }
        if ([urlWithQuerystring rangeOfString:@"?"].location == NSNotFound) {
            [urlWithQuerystring appendFormat:@"?%@=%@", [self urlEscapeString:keyString], [self urlEscapeString:valueString]];
        } else {
            [urlWithQuerystring appendFormat:@"&%@=%@", [self urlEscapeString:keyString], [self urlEscapeString:valueString]];
        }
    }
    return urlWithQuerystring;
}


- (NSArray*) splitJSON:(NSString*) jsonString
{
    NSString *exp = @"(^.*\"y\":\\d*\\.*\\d*,)(.*\"y\":\\d*\\.*\\d*,)(.*)";
    NSError *error;
    NSArray *output;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:exp options:0 error:&error];

    if (error) {
        NSLog(@"%@", error);
    }

    else
    {
        NSTextCheckingResult* result = [regex firstMatchInString:jsonString options:0 range:NSMakeRange(0, [jsonString length])];
        NSString* one = @"";
        NSString* two = @"";
        NSString* three = @"";
        
        if (result) {
            NSLog(@"%d", [result numberOfRanges]);
            for (int i = 0; i < [result numberOfRanges]; i++)
            {
                if (i == 0 && !NSEqualRanges([result rangeAtIndex:1], NSMakeRange(NSNotFound, 0)))
                    one = [jsonString substringWithRange:[result rangeAtIndex:1]];
                else if (i == 1 && !NSEqualRanges([result rangeAtIndex:2], NSMakeRange(NSNotFound, 0)))
                    two = [jsonString substringWithRange:[result rangeAtIndex:2]];
                else if (i == 2 && !NSEqualRanges([result rangeAtIndex:3], NSMakeRange(NSNotFound, 0)))
                    three = [jsonString substringWithRange:[result rangeAtIndex:3]];
            }
        }
        output = [[NSArray alloc] initWithObjects:one, two, three, nil];
    }
    return output;
}


-(void)resetRoute
{
    if (self.reset == NO)
    {
        [self.site resetRoute];
        self.directionsBanner.hidden = YES;
        self.slider.value = 0;
        self.slider.maximumValue = 1;
        self.slider.enabled = NO;
        self.routePointer = [NSNumber numberWithInt:-1];
        self.reset = YES;
        
    }
}

- (void)routeClick{
    if (self.startGraphic != nil && self.endGraphic != nil)
    {
        [self resetRoute];
        [self.site zoomToRooms];
        [self performRouting];
    }
}


- (NSOperation*)performQuery:(NSString *)where geometry:(BOOL)geometry fields:(NSArray *)fields qt:(AGSQueryTask *)qt
{
    qt.delegate = self;
    AGSQuery *query = [AGSQuery query];
    query.whereClause = where;
    query.returnGeometry = geometry;
    query.outFields = fields;
    return [qt executeWithQuery:query];
}


- (void)updateDirectionsLabel:(NSString*)newLabel {
    if (self.directionsBanner.hidden == YES)
    {
        self.directionsBanner.hidden = NO;
    }
	self.directionsLabel.text = newLabel;
}


-(void) createUI
{
    self.loadingRoomAlertView = [[ActivityAlertView alloc]
        initWithTitle:@"Please wait while room locations are downloaded..."
        message:@"\n\n"
        delegate:self cancelButtonTitle:nil
        otherButtonTitles:nil];
    
    self.activityAlertView = [[ActivityAlertView alloc]
        initWithTitle:@"Calculating Route..."
        message:@"\n\n"
        delegate:self cancelButtonTitle:@"Cancel"
        otherButtonTitles:nil];
}


//executes when self.helpLabel is touched
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    self.map.touchDelegate = self;
    self.helpLabel.text = @"";
    if (self.sketchLyr.graphicsCount > 0)
    {
        self.startGraphic = [self.sketchLyr.graphics objectAtIndex:0];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath
					  ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
    
    if ([keyPath isEqual:@"location2"]) {
        AGSMutablePoint* currentLocation = [[self.map.locationDisplay mapLocation] mutableCopy];
        AGSGraphicsLayer *layer = [[AGSGraphicsLayer alloc] init];
        self.startField.text = @"Current";
        AGSGraphic *g = [[AGSGraphic alloc]initWithGeometry:currentLocation symbol:[self markerSymbol] attributes:nil];
        [layer addGraphic:g];
        self.startGraphic = g;
        [self.map addMapLayer:layer];
        [self.map.locationDisplay stopDataSource];
        [self.map.locationDisplay removeObserver:self forKeyPath:@"location2"];
    }
}


- (AGSMarkerSymbol *) markerSymbol
{
    AGSSimpleMarkerSymbol *markerSymbol = [[AGSSimpleMarkerSymbol alloc] init];
    markerSymbol.size = CGSizeMake(20,20);
    markerSymbol.style = AGSSimpleMarkerSymbolStyleCircle;
    markerSymbol.outline.color = [UIColor whiteColor];
    markerSymbol.outline.width = 3;
    AGSColor *colour = [UIColor greenColor];
    markerSymbol.color = colour;
    return markerSymbol;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    NSString *path = [[NSBundle mainBundle] pathForResource:@"settings" ofType:@"plist"];
    self.settings = [[NSDictionary alloc] initWithContentsOfFile:path];
    [[NSURLConnection ags_trustedHosts] addObject:[self.settings objectForKey:@"host"]];
    self.cred = [[AGSCredential alloc] initWithUser:[self.settings objectForKey:@"username"] password:[self.settings objectForKey:@"password"] authenticationType:AGSAuthenticationTypeToken];
    self.roomsLoaded = NO;
    self.startRoom = @"";
    self.endRoom = @"";
    self.startRaster = @"";
    self.endRaster = @"";
    self.routePointer = [NSNumber numberWithInt:-1];
    self.reset = YES;
    self.stackNavigation = ![[self.settings valueForKey:@"stackLayer"] isEqualToString:@"NA"];
    Reachability* reachability = [Reachability reachabilityForInternetConnection];
    if(reachability.currentReachabilityStatus != NotReachable)
    {
        self.internetConnection = YES;
        [self performNetworkTasks];
    }
    else
    {
        self.internetConnection = NO;
        [self showInternetConnectionPrompt];
    }
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChanged:) name:kReachabilityChangedNotification object:nil];
    [reachability startNotifier];
    AGSPoint *p = [[AGSMutablePoint alloc] init];
    self.sketchLyr = [[AGSSketchGraphicsLayer alloc] initWithGeometry:p];
    self.sketchLyr.selectedVertexSymbol = [self markerSymbol];
    NSError *error;
    NSString* clientID = [self.settings objectForKey:@"clientId"];
    [AGSRuntimeEnvironment setClientID:clientID error:&error];
    if(error){
        // We had a problem using our client ID
        NSLog(@"Error using client ID : %@",[error localizedDescription]);
    }
    
    [self createUI];
}

-(void) showInternetConnectionPrompt
{
    UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Connection Issue"
                                                 message:@"Please connect to the Internet"
                                                delegate:self
                                       cancelButtonTitle:@"Ok" otherButtonTitles:nil];
    [av show];
}

-(void) showChooseOtherPrompt
{
    UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Same start and end locations"
                                                 message:@"Please choose another location."
                                                delegate:self
                                       cancelButtonTitle:@"Ok" otherButtonTitles:nil];
    [av show];
}

-(void) showNoRoomsPromt
{
    UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Location doesn't have any accessible entrances"
                                                 message:@"Please choose another location."
                                                delegate:self
                                       cancelButtonTitle:@"Ok" otherButtonTitles:nil];
    [av show];
}

- (void) reachabilityChanged:(NSNotification*) notification
{
	Reachability* reachability = notification.object;
    
	if (reachability.currentReachabilityStatus != NotReachable && !self.roomsLoaded)
    {
        [self performNetworkTasks];
    }
}

-(void) performNetworkTasks
{
    
    self.site = [[Site alloc]initWithCredentials:self.cred map:self.map settings:self.settings];
    
    UIColor* white = [UIColor whiteColor];
    self.map.gridLineColor = white;
    self.map.backgroundColor = white;
    self.map.gridLineWidth = 0;
    
    NSURL* Url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@",[self.settings objectForKey:@"mapService"], [self.settings objectForKey:@"roomServiceLayer"]]];
    NSArray* outputFields;
    if ([[self.settings objectForKey:@"accessible"]boolValue])
    {
        outputFields = [NSArray arrayWithObjects: @"name", @"planid", @"accessible", nil];
    }
    else
    {
        outputFields = [NSArray arrayWithObjects: @"name", @"planid", nil];
    }
    
    //if using long names, query them
    if (![[self.settings objectForKey:@"buildingServiceLayer"] isEqualToString:@"NA"])
    {
        NSURL* planUrl = [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@",[self.settings objectForKey:@"mapService"], [self.settings objectForKey:@"buildingServiceLayer"]]];
        NSArray* outFields = [NSArray arrayWithObjects: @"Name", @"NameShort", nil];
        self.planQt = [[AGSQueryTask alloc] initWithURL: planUrl credential:self.cred];
        self.planOp = [self performQuery:@"1 = 1" geometry:NO fields:outFields qt:self.planQt];
    }
    
    
    
    self.roomQt = [[AGSQueryTask alloc] initWithURL: Url credential:self.cred];
    self.roomOp = [self performQuery:@"1 = 1" geometry:YES fields:outputFields qt:self.roomQt];
    NSURL *routeTaskUrl = [NSURL URLWithString:[self.settings objectForKey:@"networkService"]];
    self.routeTask = [AGSRouteTask routeTaskWithURL:routeTaskUrl credential:self.cred];
	self.routeTask.delegate = self;
	[self.routeTask retrieveDefaultRouteTaskParameters];

    if (self.stackNavigation)
    {
        NSString *stack = [NSString stringWithFormat:@"%@/%@",[self.settings objectForKey:@"planService"], [self.settings objectForKey:@"stackLayer"]];
        NSURL* stackUrl = [NSURL URLWithString:stack];
        self.stackQt = [[AGSQueryTask alloc] initWithURL: stackUrl credential:self.cred];
        NSArray* fields = [NSArray arrayWithObjects: @"fromstack", @"tostack", @"building", @"planid", nil];
        self.stackOp = [self performQuery:@"OBJECTID > 0" geometry:YES fields:fields qt:self.stackQt];
    }
    //Get the token
    
    NSMutableURLRequest *parseRequest2 = [[NSMutableURLRequest alloc] init];
    [parseRequest2 setHTTPMethod:@"POST"];
    NSString *queryParameters = [NSString stringWithFormat:@"%@%@%@%@", @"password=", [self.settings objectForKey:@"password"] , @"&Referer=arcgisios&request=gettoken&clientid=ref.arcgisios&f=json&username=", [self.settings objectForKey:@"username"]];
    
    NSURL *tokenURL = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@/arcgis/tokens/generateToken?%@", [self.settings objectForKey:@"host"],  queryParameters]];
    
    [parseRequest2 setURL:tokenURL];
    
    [NSURLConnection sendAsynchronousRequest:parseRequest2
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                               if (data) {
                                   NSDictionary *responseDictionary = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
                                   self.token = [responseDictionary objectForKey:@"token"];
                               }
                           }];
     
}

-(void)zoomTo:(AGSMutableEnvelope *)env
{
    [env expandByFactor:2];
    [self.map zoomToEnvelope:env animated:YES];
}

-(void) operation:(NSOperation*)op didFailWithError:(NSError*)error{
    NSLog(@"%@", error);
}


-(void)drawRoute:(NSNumber*)step
{
    if (step != self.routePointer)
    {
        if ([step integerValue] == -1)
        {
            [self.site zoomToRooms];
        }
        else
        {
            [self updateDirectionsLabel:@"Routing completed"];
            [self.site showStep:step];
            [self updateDirectionsLabel:[self.site getCurrentDirectionText:self.startRoom endRoom:self.endRoom]];
            self.routePointer = step;
            if ([step integerValue] == self.slider.maximumValue)
            {
                [self.site zoomToRooms];
                [self.map zoomToScale:4000 animated:YES];
            }
        }
    }
}


#pragma mark AGSRouteTaskDelegate

// we got the default parameters from the service
- (void)routeTask:(AGSRouteTask *)routeTask operation:(NSOperation *)op didRetrieveDefaultRouteTaskParameters:(AGSRouteTaskParameters *)routeParams {
    self.routeTaskParams = routeParams;
}

//
// an error was encountered while getting defaults
//
- (void)routeTask:(AGSRouteTask *)routeTask operation:(NSOperation *)op didFailToRetrieveDefaultRouteTaskParametersWithError:(NSError *)error {
	
	// Create an alert to let the user know the retrieval failed
	// Click Retry to attempt to retrieve the defaults again
    //NSLog(@"error");
	UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Error"
             message:@"Please make sure you are connected to the Internet"
            delegate:self
   cancelButtonTitle:@"Ok" otherButtonTitles:@"Retry",nil];
	[av show];
}

- (void)routeTask:(AGSRouteTask *)routeTask operation:(NSOperation *)op didSolveWithResult:(AGSRouteTaskResult *)routeTaskResult {
    self.reset = NO;
    self.slider.hidden = NO;
    self.slider.maximumValue = [self.site addRoute:routeTaskResult] - 1;
    self.slider.enabled = YES;
    self.directionsLabel.hidden = NO;
    [self.site zoomToRooms];
    [self.activityAlertView close];
    [self drawRoute:[NSNumber numberWithInt:-1]];
}


-(void) chooseBuildings
{
    NSArray *buildings = self.site.buildingCodes;
    rootViewController *addController = [[rootViewController alloc] initWithContent:buildings];
    addController.title = @"Building Name";
    addController.tableView.delegate = self;
    self.data = addController.tableView.dataSource;
    self.navigationController.navigationBarHidden = NO;
    [self.navigationController pushViewController:addController animated:YES];
}


- (BOOL)prefersStatusBarHidden {
    return YES;
}

#pragma routing

- (IBAction)route {
    [self routeClick];
}

- (IBAction)curl {
    self.configView.hidden = NO;
    [UIView animateWithDuration:1.0

         animations:^{
             CATransition *animation = [CATransition animation];
             [animation setDuration:0.7];
             [animation setTimingFunction:[CAMediaTimingFunction functionWithName:@"default"]];
             animation.fillMode = kCAFillModeForwards;
             [animation setRemovedOnCompletion:NO];
             if (!self.isCurled) {
                 animation.endProgress = 0.7;
                 animation.type = @"pageCurl";
                 [self.mapContainer.layer addAnimation:animation forKey:@"pageCurlAnimation"];
                 [self.map addSubview:self.configView];
             }else {
                 animation.startProgress = 0.3;
                 animation.type = @"pageUnCurl";
                 [self.mapContainer.layer addAnimation:animation forKey:@"pageUnCurlAnimation"];
                 [self.configView removeFromSuperview];
             }
         }
     ];
    self.isCurled = (!self.isCurled);
}


- (IBAction)routeStep:(UISlider*) sender {
    int ctr;
    if ([sender value] == 0) ctr = -1;
    else ctr = (floor)([sender value]);
    [self drawRoute:[NSNumber numberWithInt:ctr]];
}


-(BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    if (!self.roomsLoaded)
    {
        if (self.internetConnection)
        {
            [self.loadingRoomAlertView show];
        }
        else
        {
            [self showInternetConnectionPrompt];
        }
    }
    else if ([textField isEqual:self.startField])
    {
        [self chooseBuildings];
        self.currentTextfield = @"start";
    }
    else if ([textField isEqual:self.endField])
    {
        [self chooseBuildings];
        self.currentTextfield = @"end";
    }
    else
    {
        return YES;
    }
    return NO;
}


#pragma mark AGSQueryTaskDelegates
- (void)queryTask:(AGSQueryTask *)queryTask operation:(NSOperation *)op didExecuteWithFeatureSetResult:(AGSFeatureSet *)featureSet
{
    if (op == self.roomOp)
    {
        [self.site addRooms:featureSet];
        self.roomsLoaded = YES;
        [self.loadingRoomAlertView close]; 
        
        if ([[self.settings objectForKey:@"indoorPlans"]isEqualToString:@"imageServiceLayer"])
        {
            NSURL* Url = [NSURL URLWithString:[self.settings objectForKey:@"planService"]];
            self.imageQt = [[AGSQueryTask alloc] initWithURL:Url credential:self.cred];
            self.imageOp = [self performQuery:@"OBJECTID > 0" geometry:NO fields:[NSArray arrayWithObjects: @"Name", nil] qt:self.imageQt];
        }
        AGSTiledMapServiceLayer* basemap = [AGSTiledMapServiceLayer tiledMapServiceLayerWithURL:[NSURL URLWithString:[self.settings objectForKey:@"topo"]]];
        [self.map insertMapLayer:basemap withName:@"topo" atIndex:0];
        //self.map.maxEnvelope = basemap.fullEnvelope;
    }
    else if (op == self.planOp)
    {
        [self.site addBuildingNames:featureSet];
    }
    else if (op == self.stackOp)
    {
        [self.site addStacks:featureSet];
    }
    else
    {
        [self.site addRasterLookup:featureSet];
    }
}


//if there's an error with the query display it to the user
- (void)queryTask:(AGSQueryTask *)queryTask operation:(NSOperation *)op didFailWithError:(NSError *)error {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error"
														message:[error localizedDescription]
													   delegate:nil
											  cancelButtonTitle:@"OK"
											  otherButtonTitles:nil];
    //NSLog(@"%@", error.description);
	[alertView show];
}





//if there's an error with the gp task give info to user
-(void)geoprocessor:(AGSGeoprocessor *)geoprocessor operation:(NSOperation *)op didFailExecuteWithError:(NSError *)error{
    [self.activityAlertView close];
    [self resetRoute];
}

- (void)viewDidUnload
{
    [self setCallNumber:nil];
    [self setSlider:nil];
    [self setMap:nil];
    [self setDirectionsLabel:nil];
    [self setDirectionsBanner:nil];
    [self setConfigView:nil];
    [self setConfigView:nil];
    [self setMap:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

- (IBAction)changeBasemap:(UISegmentedControl *)sender {
        
    NSString *basemapName;
    NSString *layerToRemove;
    
    if(sender.selectedSegmentIndex == 0){
        basemapName = @"topo";
        layerToRemove = @"satellite";
	}
	if(sender.selectedSegmentIndex == 1){
        basemapName = @"satellite";
        layerToRemove = @"topo";
    }
    
    [self.map removeMapLayerWithName:layerToRemove];
    
    //add new layer
    AGSTiledMapServiceLayer* newBasemapLayer = [AGSTiledMapServiceLayer tiledMapServiceLayerWithURL:[NSURL URLWithString:[self.settings objectForKey:basemapName]]];
    newBasemapLayer.name = basemapName;
    [self.map insertMapLayer:newBasemapLayer atIndex:0];
    self.map.maxEnvelope = newBasemapLayer.fullEnvelope;
    [self curl];
}




- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    //if choosing buildings
    if ([tableView.dataSource isEqual:self.data])
    {
        if ([self.currentTextfield isEqualToString:@"end"] && self.stackNavigation)
        {
            UITableViewCell *selectedCell = [tableView cellForRowAtIndexPath:indexPath];
            NSString *planName = selectedCell.textLabel.text;
            [self.navigationController popToRootViewControllerAnimated:YES];
            
            self.navigationController.navigationBarHidden = YES;
            
            [self.site hideRoom:self.startRaster room:self.startRoom];
            self.endRaster = planName;
            self.endField.text =  planName;
        }
        else
        {
            UITableViewCell *selectedCell = [tableView cellForRowAtIndexPath:indexPath];
            NSString *cellText = selectedCell.textLabel.text;
            self.currentCode = cellText;
            NSArray *rooms = [self.site.rooms objectForKey:cellText];
            NSMutableArray *list = [[NSMutableArray alloc]init];
            for (NSDictionary* room in rooms)
            {
                [list addObject:[room objectForKey:@"name"]];
            }
            rootViewController* r = [[rootViewController alloc] initWithContent:list];
            r.tableView.delegate = self;
            r.title = @"Room";
            [self.navigationController pushViewController:r animated:YES];
        }
    }
    else
    {

        UITableViewCell *selectedCell = [tableView cellForRowAtIndexPath:indexPath];
        NSString *roomName = selectedCell.textLabel.text;
        [self.navigationController popToRootViewControllerAnimated:YES];

        self.navigationController.navigationBarHidden = YES;
        
        [self.site hideRoom:self.startRaster room:self.startRoom];
        self.startRoom = roomName;
        
        NSArray * foundRooms = [self.site.rooms objectForKey:self.currentCode];
        
        NSString *plan;
        for (NSDictionary* room in foundRooms){
            if ([[room objectForKey:@"name"] isEqualToString:roomName])
            {
                plan = [room objectForKey:@"plan"];
                break;
            }
        }
        
        UIColor *color;
        if ([self.currentTextfield isEqualToString:@"start"])
        {
            self.startRaster = plan;
            self.startField.text =  [[NSArray arrayWithObjects:self.currentCode,@", ",roomName, nil] componentsJoinedByString:@""];
            self.startGraphic = [self.site getRoomGraphic:self.startRaster room:self.startRoom];
            color = [UIColor greenColor];
        }
        else
        {
            self.endRaster = plan;
            self.endField.text =  [[NSArray arrayWithObjects:self.currentCode,@", ",roomName, nil] componentsJoinedByString:@""];
            self.endGraphic = [self.site getRoomGraphic:self.endRaster room:self.startRoom];
            color = [UIColor redColor];
        }
        [self.site showRoom:plan room:roomName withColour:color];
        
    }
}


//makes return key close the keyboard
- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (!([self.endField.text isEqualToString:@""]))
    {
        self.stack = [self.site findStack:[[self.callNumber text] uppercaseString]  withLibrary:self.endField.text];
        AGSPolyline* line = [self.stack.graphic.geometry mutableCopy];
        AGSPoint* start = [line pointOnPath:0 atIndex:0];
        AGSPoint* end = [line pointOnPath:0 atIndex:1];
        
        AGSSpatialReference * sp = [[AGSSpatialReference alloc] initWithWKID:102100];
        NSArray* result = [self getMidpoint:start.x y1:start.y x2:end.x y2:end.y];
        AGSPoint* p = [[AGSPoint alloc]initWithX:[[result objectAtIndex:0] doubleValue] y:[[result objectAtIndex:1]doubleValue] spatialReference:sp];
        AGSGraphic *out = [AGSGraphic graphicWithGeometry:p symbol:nil attributes:nil];

        if (out != nil)
        {
            self.endGraphic = out;
        }
    }
    [textField resignFirstResponder];
    return YES;
}


- (NSArray*) getMidpoint:(double)x1 y1:(double)y1 x2:(double)x2 y2:(double)y2
{
    double deltaX = x2 - (x2 - x1)/2.0;
    double deltaY = y2 - (y2 - y1)/2.0;
    return [NSArray arrayWithObjects:[NSNumber numberWithFloat:deltaX],[NSNumber numberWithFloat:deltaY], nil];
}

@end
