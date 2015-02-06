//
//  RootViewController.m
//  IndexedTable
//
//  Created by Vladimir Olexa on 2/21/10.
//  Copyright Vladimir Olexa 2010. All rights reserved.
//

#import "rootViewController.h"


@implementation rootViewController

#pragma mark -
#pragma mark View lifecycle


-initWithContent:(NSArray*)rooms
{
    self = [super init];
    self.content = [self wordsFromLetters:rooms];
    self.indices = [self.content valueForKey:@"headerTitle"];
    return self;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    
}

#pragma mark -
#pragma mark Table view data source

// Customize the number of sections in the table view.
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [self.content count];
}

// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [[[self.content objectAtIndex:section] objectForKey:@"rowValues"] count] ;
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                       reuseIdentifier:CellIdentifier];
    }
    cell.textLabel.text = [[[self.content objectAtIndex:indexPath.section] objectForKey:@"rowValues"]
                           objectAtIndex:indexPath.row];
    
    return cell;
}

- (NSString *)tableView:(UITableView *)aTableView titleForHeaderInSection:(NSInteger)section {
	return [[self.content objectAtIndex:section] objectForKey:@"headerTitle"];
    
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView {
    return [self.content valueForKey:@"headerTitle"];
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index {
    return [self.indices indexOfObject:title];
}


#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
}



#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Relinquish ownership any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
    // Relinquish ownership of anything that can be recreated in viewDidLoad or on demand.
    // For example: self.myOutlet = nil;
}


- (void)dealloc {

}


- (NSArray *) wordsFromLetters:(NSArray*)input {
    NSMutableSet *firstCharacters = [[NSMutableSet alloc] init];
    
    NSMutableArray *content = [[NSMutableArray alloc] init];
    
    NSMutableDictionary *row = [[NSMutableDictionary alloc] init];
    NSMutableArray *words = [[NSMutableArray alloc] init];

    NSString *lastChar = [[input objectAtIndex:0] substringToIndex:1];
    NSString *currentChar  = @"";
    

    for (NSString*name in input)
    {
            
        currentChar = [name substringToIndex:1];
        
        if ([currentChar isEqualToString:lastChar])
        {
            [words addObject:name];
            
        }
        else
        {
            while ([firstCharacters containsObject:lastChar])
            {
                lastChar = [lastChar stringByAppendingString:@".."];
            }
            [firstCharacters addObject:lastChar];
            
            [row setValue:lastChar forKey:@"headerTitle"];
            [row setValue:words forKey:@"rowValues"];
            [content addObject:row];
            
            //reinitialize
            words = [[NSMutableArray alloc] init];
            [words addObject:name];
            row = [[NSMutableDictionary alloc] init];
            lastChar = currentChar;
        }
    }
    
    [row setValue:lastChar forKey:@"headerTitle"];
    [row setValue:words forKey:@"rowValues"];
    [content addObject:row];

    return content;
}

@end

