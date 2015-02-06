//
//  mapAppDelegate.h
//
//
//  Created by admin on 12-08-17.
//  Copyright (c) 2012 Esri Canada. All rights reserved.
//

#import <UIKit/UIKit.h>

@class mapViewController;

@interface mapAppDelegate : UIResponder <UIApplicationDelegate, UINavigationControllerDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (strong, nonatomic) mapViewController *viewController;

@end

