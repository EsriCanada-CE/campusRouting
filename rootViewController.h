//
//  RootViewController.h
//  IndexedTable
//
//  Created by Vladimir Olexa on 2/21/10.
//  Copyright Vladimir Olexa 2010. All rights reserved.
//




@interface rootViewController : UITableViewController
@property (retain, strong) NSArray *content;
@property (retain, strong) NSArray *indices;
-initWithContent:(NSArray*)rooms;
@end
