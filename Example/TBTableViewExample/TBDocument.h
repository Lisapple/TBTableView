//
//  TBDocument.h
//  TBTableViewExample
//
//  Created by Max on 3/26/14.
//  Copyright (c) 2014 Lisacintosh. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "TableView.h" // Just import "TableView" header

@interface TBDocument : NSDocument <TableViewDelegate, TableViewDataSource>

@property (nonatomic, weak) IBOutlet TableView * tableView;

@end
