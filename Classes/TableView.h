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
{
	NSInteger numberOfSections, oldNumberOfSections;
	NSInteger * numberOfRows;// An array with the number rows into each section (the count of the array is equal to "numberOfSections")
	NSInteger totalHeight;// The total height of all rows
	NSMutableArray * sectionsRows;// All the rows into an array for each section (-> array of array)
	NSArray * sectionsView;// All section views
	CGFloat * sectionsHeight;// The size of the section (with all rows and the section header), include the height of the separator
	CGFloat * rowsHeight;// Height of all rows
	BOOL * showsClosureButtons;
	TableViewSectionState * sectionsState;
	
	NSInteger selectedSection;
	NSIndexPath * selectedIndexPath;
	
	_TableViewSelectionView * draggingView;
	
	unsigned int * sectionsEvents;
	unsigned int * cellsEvents;
	
	BOOL isTrackingSections, isTrackingCells;
}

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
