//
//  TableViewDelegate.h
//  Pods
//
//  Created by Max on 19/07/15.
//
//

#import <AppKit/AppKit.h>

@class TableView;

typedef NS_ENUM(NSUInteger, TableViewCellEvent) {
	TableViewCellEventMouseEntered = 1,
	TableViewCellEventMouseExited = 1 << 1,
};

typedef NS_ENUM(NSUInteger, TableViewSectionState) {
	TableViewSectionStateOpen = 0,
	TableViewSectionStateClose,
	TableViewSectionStateUnknown
};

typedef NS_ENUM(NSUInteger, TableViewPosition) {
	TableViewPositionNone = 0,
	TableViewPositionTop,
	TableViewPositionMiddle,
	TableViewPositionBottom
};

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
- (NSView *)placeholderAccessoryViewForTableView:(TableView *)tableView; // @TODO: Implement it

- (BOOL)tableView:(TableView *)tableView couldCloseSection:(NSInteger)section;

@end
