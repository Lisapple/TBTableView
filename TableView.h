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

#import "PlaceholderLabel.h"

#import "NSIndexPath+additions.h"
#import "NSView+additions.h"
#import "NSNotificationCenter+additions.h"

@class TableView;

@interface TableDocumentView : NSView
@end

enum _TableViewCellEvent {
	TableViewCellEventMouseEntered = 1,
	TableViewCellEventMouseExited = 1 << 1,
};
typedef enum _TableViewCellEvent TableViewCellEvent;

enum _TableViewSectionState {
	TableViewSectionStateOpen = 0,
	TableViewSectionStateClose,
	TableViewSectionStateUnknown
};
typedef enum _TableViewSectionState TableViewSectionState;

enum _TableViewPosition {
	TableViewPositionNone = 0,
	TableViewPositionTop,
	TableViewPositionMiddle,
	TableViewPositionBottom
};
typedef enum _TableViewPosition TableViewPosition;

@protocol TableViewDelegate <NSObject>

@optional
/* Cell Section */
- (BOOL)tableView:(TableView *)tableView shouldSelectCell:(TableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath;
- (void)tableView:(TableView *)tableView didSelectCell:(TableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath;

/* Double Click on cell */
- (void)tableView:(TableView *)tableView didDoubleClickOnCell:(TableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath;

/* Text editing on sections and cells */
- (void)tableView:(TableView *)tableView setString:(id)stringValue forSection:(NSInteger)section;
- (void)tableView:(TableView *)tableView setString:(id)stringValue forCellAtIndexPath:(NSIndexPath *)indexPath;

/* Right-Click Menu */
- (NSMenu *)rightClickMenuForTableView:(TableView *)tableView forSection:(NSInteger)section;
- (NSMenu *)rightClickMenuForTableView:(TableView *)tableView forCellAtIndexPath:(NSIndexPath *)indexPath;
// @TODO: implement this delegate or do it automaticly - (BOOL)tableViewShouldDeselectRowWhenRightMenuDismissed:(TableView *)tableView;

/* Drag & Drop Managment */
- (BOOL)tableView:(TableView *)tableView allowsDragOnSection:(NSInteger)section;
- (BOOL)tableView:(TableView *)tableView allowsDragOnCellAtIndexPath:(NSIndexPath *)indexPath;

- (BOOL)tableView:(TableView *)tableView shouldDragItems:(NSArray *)pasteboardItems atIndexPath:(NSIndexPath *)indexPath;
// @TODO: implement: - (NSIndexPath *)tableView:(TableView *)tableView indexPathForItems:(NSArray *)pasteboardItems proposedIndexPath:(NSIndexPath *)indexPath;
- (NSDragOperation)tableView:(TableView *)tableView dragOperationForItems:(NSArray *)items proposedOperation:(NSDragOperation)proposedDragOp atIndexPath:(NSIndexPath *)indexPath;
- (void)tableView:(TableView *)tableView didDragItems:(NSArray *)pasteboardItems withDraggingInfo:(id <NSDraggingInfo>)draggingInfo atIndexPath:(NSIndexPath *)indexPath;

/* Showing/Hidding section */
- (void)tableView:(TableView *)tableView didChangeState:(TableViewSectionState)state ofSection:(NSInteger)section;

/* Section tracking, return a C-bitwise 'OR' mask with values from TableViewCellEvent */
- (TableViewCellEvent)tableView:(TableView *)tableView tracksEventsForSection:(NSInteger)section;
- (void)tableView:(TableView *)tableView didReceiveEvent:(TableViewCellEvent)event forSection:(NSInteger)section;

/* Cell tracking, return a C-bitwise 'OR' mask with values from TableViewCellEvent */
- (TableViewCellEvent)tableView:(TableView *)tableView tracksEventsForCell:(TableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath;
- (void)tableView:(TableView *)tableView didReceiveEvent:(TableViewCellEvent)event forCell:(TableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath;

/* Resizing delegate */
- (void)tableView:(TableView *)tableView willResize:(NSSize)newSize;
- (BOOL)tableView:(TableView *)tableView shouldInvalidateContentLayoutForSize:(NSSize)newSize;
- (void)tableView:(TableView *)tableView didResize:(NSSize)size;

//- (void)tableView:(TableView *)tableView didReceiveKeyCode:(unsigned short)keyCode; => deprecated
- (void)tableView:(TableView *)tableView didReceiveKeyString:(NSString *)keyString;

@end

@protocol TableViewDataSource <NSObject>

- (NSInteger)numberOfSectionsInTableView:(TableView *)tableView;
- (NSArray *)titlesForSectionsInTableView:(TableView *)tableView;
- (NSInteger)tableView:(TableView *)tableView numberOfRowsInSection:(NSInteger)section;

- (TableViewCell *)tableView:(TableView *)tableView cellForIndexPath:(NSIndexPath *)indexPath;

@optional
- (CGFloat)tableView:(TableView *)tableView rowHeightAtIndex:(NSIndexPath *)indexPath;

- (NSString *)placeholderForTableView:(TableView *)tableView;

- (BOOL)tableView:(TableView *)tableView couldCloseSection:(NSInteger)section;

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
	
	PlaceholderLabel * placeholderLabel;
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
