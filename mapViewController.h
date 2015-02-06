//
//  mapViewController.h
//  Waterloo Map
//
//  Created by admin on 12-08-14.
//  Copyright (c) 2012 Esri Canada. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <ArcGIS/ArcGIS.h>
#import "ActivityAlertView.h"
#import "Site.h"
#import "Reachability.h"
#import "BookStackLOCRange.h"
#import "rootViewController.h"


@interface mapViewController : UIViewController  <UITextFieldDelegate, AGSMapViewLayerDelegate, AGSQueryTaskDelegate, AGSRouteTaskDelegate, UITableViewDelegate, UINavigationControllerDelegate, AGSMapViewTouchDelegate>

@property (strong, nonatomic) IBOutlet UIView *directionsBanner;    //bar on bottom of screen that displays the directions
@property (strong, nonatomic) IBOutlet UILabel *directionsLabel;    //Label text that contains instructions
@property (strong, nonatomic) IBOutlet UITextField *callNumber;     //start textfield of interface
@property (strong, nonatomic) IBOutlet UISwitch *toggle;            //indoor/outdoor switch of interface
@property (strong, nonatomic) IBOutlet UISlider *slider;            //navigation slider of interface
@property (strong, nonatomic) IBOutlet AGSMapView *map;             //map object
@property (strong, nonatomic) IBOutlet UIButton *curlControl;       //button that open settings
@property (strong, nonatomic) IBOutlet UIView *configView;          //view containing basemap picker
@property (strong, nonatomic) IBOutlet UIView *mapContainer;        //view containing the map
@property (strong, nonatomic) IBOutlet UITextField *endField;       //end textfield of interface
@property (strong, nonatomic) IBOutlet UITextField *startField;     //start textfield of interface
@property (strong, nonatomic) IBOutlet UILabel *helpLabel;

@end
