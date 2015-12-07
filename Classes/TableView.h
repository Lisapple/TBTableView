//
//  TableView.h
//  TableView
//
//  Created by Max on 11/10/12.
//  Copyright (c) 2012 Lis@cintosh. All rights reserved.
//

#import <AppKit/AppKit.h>

#import "TableViewCell.h"
#import "TableViewSection.h"
#import "TableViewDelegate.h"

#import "PlaceholderLabel.h"

#import "NSIndexPath+additions.h"
#import "NSView+additions.h"
#import "NSNotificationCenter+additions.h"

@interface TableDocumentView : NSView
@end

@interface _TableViewSelectionView : NSView
{
	NSBezierPath * bezierPath;
	NSRect innerRect;
}

- (void)drawRectStroke:(NSRect)rect;

@end

// @TODO: permettre de sélectionner plusieurs cellules

@interface TableView : NSScrollView <NSTextFieldDelegate, NSMenuDelegate, TableViewSectionClosureButtonProtocol>

@property (nonatomic, strong) NSObject <TableViewDelegate> * delegate;
@property (nonatomic, strong) NSObject <TableViewDataSource> * dataSource;

@property (nonatomic, assign) NSInteger rowHeight;
@property (nonatomic, copy) NSColor * separatorColor;

- (void)reloadData;
- (void)reloadSectionsTitles;
- (void)reloadDataForSection:(NSInteger)section;
- (void)reloadDataForCellAtIndexPath:(NSIndexPath *)indexPath;

- (void)updateContentLayout;

- (TableViewCell *)cellAtIndexPath:(NSIndexPath *)indexPath;
- (NSIndexPath *)indexPathForCellAtPoint:(NSPoint)point;

- (void)selectRowAtIndexPath:(NSIndexPath *)indexPath;
- (NSIndexPath *)indexPathOfSelectedRow;
- (NSInteger)selectedSection;
- (void)deselectRowAtIndexPath:(NSIndexPath *)indexPath;
- (void)deselectSelectedRowAnimated:(BOOL)animated;

- (TableViewSectionState)stateForSection:(NSInteger)section;
- (void)setState:(TableViewSectionState)sectionState forSection:(NSInteger)section;

- (void)startTrackingSections;
- (void)stopTrackingSections;
- (void)startTrackingCells;
- (void)stopTrackingCells;

// @TODO: implement this method
//- (void)setAlternativeBackgroundWithColorStyle:(TableViewCellBackgroundColorStyle)firstColorStyle andColorStyle:(TableViewCellBackgroundColorStyle)secondColorStyle;

- (void)scrollToRowAtIndexPath:(NSIndexPath *)indexPath position:(TableViewPosition)position;
- (void)scrollToSection:(NSInteger)section openSection:(BOOL)open position:(TableViewPosition)position;

- (void)enableEditing:(BOOL)editing forSection:(NSInteger)section;
- (void)enableCellEditing:(BOOL)editing atIndexPath:(NSIndexPath *)indexPath;

- (NSPoint)convertLocationFromWindow:(NSPoint)locationInWindow;

- (void)invalidateContentLayout;

@end
