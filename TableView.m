//
//  TableView.m
//  TableView
//
//  Created by Max on 11/10/12.
//  Copyright (c) 2012 Lis@cintosh. All rights reserved.
//

#import "TableView.h"

const NSString * kTrackedViewKey = @"trackedView";
const NSString * kSectionKey = @"section";
const NSString * kIndexPathKey = @"indexPath";

@implementation TableDocumentView

- (BOOL)isFlipped
{
	return YES;
}

- (BOOL)acceptsFirstResponder
{
	return YES;
}

- (BOOL)becomeFirstResponder
{
	return YES;
}

- (void)drawRect:(NSRect)dirtyRect
{
	[[NSColor colorWithCalibratedWhite:0.75 alpha:1.] setFill];
	NSRectFill(dirtyRect);
}

@end

@implementation _TableViewSelectionView

#define kStrokeWidth 3.

- (void)drawRectStroke:(NSRect)rect
{
	innerRect = NSZeroRect;
	
	if (rect.size.width > 0. && rect.size.height > 0.) {
		innerRect = CGRectMake(rect.origin.x + (kStrokeWidth / 2.), rect.origin.y + (kStrokeWidth / 2.), rect.size.width - kStrokeWidth, rect.size.height - kStrokeWidth);
	}
	
	[self setNeedsDisplay:YES];
}

- (void)drawRect:(NSRect)dirtyRect
{
	if (innerRect.size.width > 0. && innerRect.size.height > 0.) {
		[[NSColor grayColor] setStroke];
		CGContextRef context = [NSGraphicsContext currentContext].graphicsPort;
		CGContextSetLineWidth(context, kStrokeWidth);
		CGContextStrokeRect(context, NSRectToCGRect(innerRect));
	} else {
		[[NSColor grayColor] setFill];
		NSRectFill(dirtyRect);
	}
}

@end


@interface TableView (PrivateMethods)

- (void)selectSection:(NSInteger)section;
- (void)deselectSelectedSection;

- (void)removeAllEventsTracking;
- (CGFloat)heightForSection:(NSInteger)section;
- (NSIndexPath *)indexPathForCell:(TableViewCell *)cell;
- (NSRect)rectForSection:(NSInteger)section includeSectionHeader:(BOOL)withSection;

- (NSInteger)rowIndexForIndexPath:(NSIndexPath *)indexPath;

@end


@implementation TableView

const CGFloat kSectionHeight = 20.;

@synthesize delegate = _delegate, dataSource = _dataSource;
@synthesize rowHeight = _rowHeight;
@synthesize separatorColor = _separatorColor;

- (id)initWithCoder:(NSCoder *)aDecoder
{
	if ((self = [super initWithCoder:aDecoder])) {
		_rowHeight = 17.;
		self.separatorColor = [NSColor lightGrayColor];
		
		self.backgroundColor = [NSColor colorWithCalibratedWhite:(243. / 255.) alpha:1.];// = 0.871 
		
		isTrackingSections = isTrackingCells = NO;
		
		/* Reload the tableView when the tint change */
		[[NSNotificationCenter defaultCenter] addObserverForName:NSControlTintDidChangeNotification
													  usingBlock:^(NSNotification *notification) {
														  TableViewCell * cell = [self cellAtIndexPath:[self indexPathOfSelectedRow]];
														  cell.selectedColorStyle = cell.selectedColorStyle;
														  [cell setNeedsDisplay:YES];
													  }];
	}
	
	return self;
}

- (BOOL)isFlipped
{
	return YES;
}

- (BOOL)acceptsFirstResponder
{
	return YES;
}

- (BOOL)canBecomeKeyView
{
	return YES;
}

#pragma mark - Sections & Cells Editing

- (void)enableEditing:(BOOL)editing forSection:(NSInteger)section
{
	TableViewSection * sectionView = sectionsView[section];
	sectionView.editable = editing;
	[self.window makeFirstResponder:(editing)? sectionView.textField: nil];
}

- (void)enableCellEditing:(BOOL)editing atIndexPath:(NSIndexPath *)indexPath
{
	TableViewCell * cell = [self cellAtIndexPath:indexPath];
	cell.editable = editing;
	[self.window makeFirstResponder:(editing)? cell.textField: nil];
}

#pragma mark - Cell Selection/Deselection

// @TODO: Add a method to deselect cell with animation
- (void)deselectSelectedRowAnimated:(BOOL)animated
{
	// @TODO: Create a AnimationBlock class (subclass of NSAnimation) to create block-based animations
	TableViewCell * selectedCell = [self cellAtIndexPath:selectedIndexPath];
	[selectedCell setSelected:NO animated:animated];
}

- (void)selectRowAtIndexPath:(NSIndexPath *)indexPath
{
	TableViewCell * oldCell = [self cellAtIndexPath:selectedIndexPath];
	oldCell.selected = NO;
	
	selectedIndexPath = [indexPath copy];
	
	TableViewCell * cell = [self cellAtIndexPath:selectedIndexPath];
	cell.selected = YES;
}

- (NSIndexPath *)indexPathOfSelectedRow
{
	return selectedIndexPath;
}

- (NSInteger)selectedSection
{
	return selectedSection;
}

- (void)deselectRowAtIndexPath:(NSIndexPath *)indexPath
{
	TableViewCell * cell = [self cellAtIndexPath:indexPath];
	cell.selected = NO;
	
	if (indexPath.section == selectedIndexPath.section && indexPath.row == selectedIndexPath.row) {
		selectedIndexPath = nil;
	}
}

#pragma mark - Section Selection/Deselection

- (void)selectSection:(NSInteger)section
{
	[self deselectSelectedSection];
	if (0 <= section && section < sectionsView.count) {
		((TableViewSection *)sectionsView[section]).selected = YES;
		selectedSection = section;
	}
}

- (void)deselectSelectedSection
{
	if (0 <= selectedSection && selectedSection < sectionsView.count) {
		((TableViewSection *)sectionsView[selectedSection]).selected = NO;
	}
	selectedSection = -1;
}

- (void)deselectSection:(NSInteger)section
{
	if (0 <= section && section < sectionsView.count) {
		((TableViewSection *)sectionsView[section]).selected = NO;
	}
	selectedSection = -1;
}

#pragma mark - Section State Management

- (TableViewSectionState)stateForSection:(NSInteger)section
{
	TableViewSectionState sectionState = sectionsState[section];
	return sectionState;
}

- (void)setState:(TableViewSectionState)sectionState forSection:(NSInteger)section
{
	sectionsState[section] = sectionState;
	if (sectionState == TableViewSectionStateOpen || sectionState == TableViewSectionStateClose) {
		TableViewSection * sectionView = sectionsView[section];
		if (sectionView.showsClosureButton) {
			sectionView.closureButton.state = (sectionState == TableViewSectionStateOpen)? NSOnState : NSOffState;
		}
	}
}

#pragma mark - Reload Sections Titles and Entire TableView

- (void)reloadSectionsTitles
{
	NSArray * sectionsTitle = [_dataSource titlesForSectionsInTableView:self];
	for (int section = 0; section < numberOfSections; section++) {
		TableViewSection * sectionView = sectionsView[section];
		sectionView.title = sectionsTitle[section];
	}
}

- (void)reloadData
{
	BOOL shouldResumeTrackingSections = NO, shouldResumeTrackingCells = NO;
	if (isTrackingSections) { shouldResumeTrackingSections = YES; [self stopTrackingSections]; }
	if (isTrackingCells) { shouldResumeTrackingCells = YES; [self stopTrackingCells]; }
	
	numberOfSections = [_dataSource numberOfSectionsInTableView:self];
	
	if (numberOfRows) free(numberOfRows);
	numberOfRows = (NSInteger *)malloc(numberOfSections * sizeof(NSInteger));
	
	NSArray * sectionsTitle = [_dataSource titlesForSectionsInTableView:self];
	
	NSInteger totalOfRows = 0;
	sectionsRows = [[NSMutableArray alloc] initWithCapacity:numberOfSections];
	for (int section = 0; section < numberOfSections; section++) {
		NSInteger rowCount = [_dataSource tableView:self numberOfRowsInSection:section];
		NSMutableArray * sectionRows = [[NSMutableArray alloc] initWithCapacity:numberOfSections];
		
		for (int row = 0; row < rowCount; row++) {
			NSIndexPath * indexPath = [[NSIndexPath alloc] initWithSection:section row:row];
			TableViewCell * cell = [_dataSource tableView:self cellForIndexPath:indexPath];
			[sectionRows addObject:cell];
		}
		
		[sectionsRows addObject:(NSArray *)sectionRows];
		
		totalOfRows += rowCount;
		numberOfRows[section] = rowCount;
	}
	
	CGFloat width = self.contentView.documentRect.size.width;
	
	if (sectionsHeight) free(sectionsHeight);
	sectionsHeight = (CGFloat *)malloc(numberOfSections * sizeof(CGFloat));
	
	if (rowsHeight) free(rowsHeight);
	rowsHeight = (CGFloat *)malloc(totalOfRows * sizeof(CGFloat));
	
	/* Remove sections and cells from documentView */
	NSArray * subviewsCopy = [[(NSView *)self.documentView subviews] copy];
	for (NSView * subview in subviewsCopy) {
		[subview removeFromSuperview];
	}
	
	BOOL respondsToRowHeight = ([_dataSource respondsToSelector:@selector(tableView:rowHeightAtIndex:)]);
	
	if (showsClosureButtons) free(showsClosureButtons);
	showsClosureButtons = (BOOL *)malloc(numberOfSections * sizeof(BOOL));
	
	if (numberOfSections != oldNumberOfSections) {
		TableViewSectionState * sectionsStateCopy = (TableViewSectionState *)calloc(numberOfSections, sizeof(TableViewSectionState));
		if (sectionsState) {
			for (int i = 0; i < MIN(numberOfSections, oldNumberOfSections); i++)
				sectionsStateCopy[i] = sectionsState[i];
			free(sectionsState);
		}
		sectionsState = sectionsStateCopy;
	}
	
	// @TODO: merge this code block with the upper one
	NSMutableArray * _sectionsView = [[NSMutableArray alloc] initWithCapacity:numberOfSections];
	NSInteger section = 0, row = 0;
	CGFloat offsetY = 0., sectionHeight = 0.;
	totalHeight = 0.;
	for (NSArray * sectionRows in sectionsRows) {
		CGRect frame = CGRectMake(0., offsetY, width, kSectionHeight);
		TableViewSection * sectionView = [[TableViewSection alloc] initWithFrame:frame];
		sectionView.autoresizingMask = NSViewWidthSizable;
		sectionView.title = sectionsTitle[section];
		/* Set the delegate of the section's textField to "self" to catch editing change */
		sectionView.textField.delegate = self;
		
		TableViewSectionState sectionState = sectionsState[section];
		
		if ([_dataSource respondsToSelector:@selector(tableView:couldCloseSection:)]) {
			BOOL showsClosureButton = [_dataSource tableView:self couldCloseSection:section];
			sectionView.showsClosureButton = showsClosureButton;
			if (showsClosureButton) {
				/* If we show the closure button (the little arrow near the title), change the closure button's state from "sectionState" (open by default) */
				sectionView.closureButton.state = (sectionState == TableViewSectionStateClose)? NSOffState : NSOnState;
				[sectionView addTargetForClosureButton:self];
			}
			/* Cache "showsClosureButton" value for "heightForSection:" (optimization) */
			showsClosureButtons[section] = showsClosureButton;
		}
		
		[_sectionsView addObject:sectionView];
		
		offsetY += kSectionHeight;
		sectionHeight = kSectionHeight;
		
		int rowIndex = 0;
		CGFloat y = offsetY;
		for (TableViewCell * cell in sectionRows) {
			
			CGFloat rowHeight = _rowHeight;
			if (respondsToRowHeight) {
				NSIndexPath * indexPath = [[NSIndexPath alloc] initWithSection:section row:rowIndex];
				rowHeight = [_dataSource tableView:self rowHeightAtIndex:indexPath];
			}
			rowsHeight[row] = rowHeight + 1.;// The height of the row + 1px for the separator
			
			cell.frame = NSMakeRect(0., y, width, rowHeight);
			cell.autoresizingMask = NSViewWidthSizable;
			[cell setHidden:(sectionState == TableViewSectionStateClose)];
			[self.documentView addSubview:cell];
			y += (rowHeight + 1.);
			sectionHeight += (rowHeight + 1.);
			
			/* Set the delegate of the section's textField to "self" to catch editing change */
			cell.textField.delegate = self;
			
			rowIndex++;
			row++;
		}
		
		sectionsHeight[section] = sectionHeight;
		/* The the section is closed, just add the height of the section header ("kSectionHeight") to "totalHeight"; if the section is open, add the height of the entire section to "totalHeight" and to  "offsetY" (less the height og the section header, already added) */
		if (sectionState == TableViewSectionStateClose) { totalHeight += kSectionHeight; }
		else { totalHeight += sectionHeight; offsetY += (sectionHeight - kSectionHeight); }
		
		section++;
	}
	sectionsView = (NSArray *)_sectionsView;
	
	/* Add section headers at last to set sections upper cells */
	for (TableViewSection * sectionView in sectionsView) {
		[self.documentView addSubview:sectionView];
	}
	
	
	if ([_dataSource respondsToSelector:@selector(placeholderForTableView:)]) {
		NSString * placeholder = [_dataSource placeholderForTableView:self];
		
		if (placeholder.length > 0) {
			[placeholderLabel removeFromSuperview];
			
			NSRect rect = self.contentView.documentRect;
			rect.origin = NSMakePoint(0., (int)(totalHeight + ((rect.size.height - totalHeight - 30.) / 2.)));
			rect.size.height = 30.;
			placeholderLabel = [[PlaceholderLabel alloc] initWithFrame:rect];
			placeholderLabel.autoresizingMask = NSViewWidthSizable;
			placeholderLabel.backgroundColor = self.backgroundColor;
			[self.contentView addSubview:placeholderLabel];
			
			placeholderLabel.title = placeholder;
			
		} else {
			[placeholderLabel removeFromSuperview];
			placeholderLabel = nil;
		}
	}
	
	
	NSSize size = ((NSView *)self.documentView).frame.size;
	[self.documentView setFrameSize:NSMakeSize(size.width, totalHeight)];
	
	/* Update "oldNumberOfSections" from "numberOfSections" */
	oldNumberOfSections = numberOfSections;
	
	if (shouldResumeTrackingSections) [self startTrackingSections];
	if (shouldResumeTrackingCells) [self startTrackingCells];
}

- (void)reloadDataForSection:(NSInteger)section
{
	if (section < 0 || section >= sectionsRows.count)
		return ;
	
	NSArray * cellsCopy = [sectionsRows[section] mutableCopy];
	for (TableViewCell * cell in cellsCopy) {
		[cell removeFromSuperview];
	}
	
	/* Ask the delegate for the number of row in this section */
	NSInteger _numberOfRows = [_dataSource tableView:self numberOfRowsInSection:section];
	numberOfRows[section] = _numberOfRows;
	
	/* Ask the delegate for rows' heights (update "rowsHeight" and "sectionsHeight") */
	BOOL respondsToRowHeight = ([_dataSource respondsToSelector:@selector(tableView:rowHeightAtIndex:)]);
	
	NSMutableArray * sectionRows = [[NSMutableArray alloc] initWithCapacity:_numberOfRows];
	
	NSRect sectionRect = [self rectForSection:section includeSectionHeader:NO];
	CGFloat sectionHeight = 0., y = sectionRect.origin.y;
	NSInteger rowIndex = [self rowIndexForIndexPath:[NSIndexPath indexPathWithSection:section row:0]];
	for (int index = 0; index < _numberOfRows; index++) {
		
		NSIndexPath * indexPath = [[NSIndexPath alloc] initWithSection:section row:index];
		
		CGFloat rowHeight = _rowHeight;
		if (respondsToRowHeight) {
			rowHeight = [_dataSource tableView:self rowHeightAtIndex:indexPath];
		}
		rowsHeight[rowIndex] = (rowHeight + 1.);// The height of the row + 1px for the separator
		sectionHeight += (rowHeight + 1.);
		y += (rowHeight + 1.);
		
		/* Ask the delegate for all rows in section */
		TableViewCell * cell = [self.dataSource tableView:self cellForIndexPath:indexPath];
		
		CGRect frame = cell.frame;
		frame.origin.y = y;
		frame.size.height = rowHeight;
		frame.size.width = sectionRect.size.width;
		cell.frame = frame;
		
		cell.autoresizingMask = NSViewWidthSizable;
		[cell setHidden:(sectionsState[section] == TableViewSectionStateClose)];
		[self.documentView insertView:cell atIndex:0];
		[sectionRows addObject:cell];
		
		/* Set the delegate of the section's textField to "self" to catch editing change */
		cell.textField.delegate = self;
		
		rowIndex++;
	}
	
	sectionsHeight[section] = kSectionHeight + sectionHeight;
	
	sectionsRows[section] = sectionRows;
	
	[self updateContentLayout];
}

- (void)reloadDataForCellAtIndexPath:(NSIndexPath *)indexPath
{
	CGFloat oldRowHeight = rowsHeight[indexPath.row];
	CGFloat rowHeight = _rowHeight;
	if ([_dataSource respondsToSelector:@selector(tableView:rowHeightAtIndex:)]) {
		rowHeight = [_dataSource tableView:self rowHeightAtIndex:indexPath];
	}
	rowHeight += 1.;// The height of the row + 1px for the separator
	
	NSInteger rowIndex = [self rowIndexForIndexPath:indexPath];
	rowsHeight[rowIndex] = rowHeight;
	sectionsHeight[indexPath.section] += (rowHeight - oldRowHeight);
	
	[self updateContentLayout];
}

#pragma mark - Scrolling Methods

- (void)scrollToRowAtIndexPath:(NSIndexPath *)indexPath position:(TableViewPosition)position
{
	// @TODO: Scrolls to see the row at "indexPath", depending of "position", scrolls to see the row at bottom/top/middle or the shortest way
	
	TableViewCell * cell = [self cellAtIndexPath:indexPath];
	[[self documentView] scrollPoint:NSMakePoint(0., cell.frame.origin.y)];
}

- (void)scrollToSection:(NSInteger)section openSection:(BOOL)open position:(TableViewPosition)position
{
	// @TODO: Scrolls to see the entire section (with all rows), depending of "position", scrolls to see the row at bottom/top/middle or the shortest way
	
	if (showsClosureButtons[section])
		[self setState:TableViewSectionStateOpen forSection:section];
	
	CGFloat offsetY = 0.;
	for (int i = 0; i < section; i++) { offsetY += [self heightForSection:i]; }
	[[self documentView] scrollPoint:NSMakePoint(0., offsetY)];
}

#pragma mark - Section and Cell Tracking

- (void)startTrackingSections
{
	if (isTrackingSections)
		[self stopTrackingSections];
	
	BOOL delegateResponds = ([_delegate respondsToSelector:@selector(tableView:tracksEventsForSection:)]);
	if (delegateResponds) {
		sectionsEvents = (unsigned int *)malloc(numberOfSections * sizeof(unsigned int));
		
		/* Add tracking rect for each section */
		for (int section = 0; section < numberOfSections; section++) {
			TableViewSection * sectionView = sectionsView[section];
			/* Ask the delegate before tracking */
			TableViewCellEvent eventMask = [_delegate tableView:self tracksEventsForSection:section];
			sectionsEvents[section] = eventMask;
			if (eventMask > 0) {
				NSDictionary * userInfo = @{ kTrackedViewKey : sectionView, kSectionKey : @(section)};
				NSRect frame = NSMakeRect(0., 0., sectionView.frame.size.width, sectionView.frame.size.height);
				NSTrackingArea * trackingArea = [[NSTrackingArea alloc] initWithRect:frame
																			 options:(NSTrackingMouseEnteredAndExited | NSTrackingActiveInKeyWindow | NSTrackingInVisibleRect)
																			   owner:self
																			userInfo:userInfo];
				[sectionView addTrackingArea:trackingArea];
			}
		}
	}
	
	isTrackingSections = YES;
}

- (void)stopTrackingSections
{
	for (int section = 0; section < numberOfSections; section++) {
		TableViewSection * sectionView = sectionsView[section];
		NSArray * trackingAreasCopy = [sectionView.trackingAreas copy];
		for (NSTrackingArea * trackingArea in trackingAreasCopy)
			[sectionView removeTrackingArea:trackingArea];
	}
	
	if (sectionsEvents) free(sectionsEvents);
	sectionsEvents = NULL;
	
	isTrackingSections = NO;
}

- (void)startTrackingCells
{
	if (isTrackingCells)
		[self stopTrackingCells];
	
	BOOL delegateResponds = ([_delegate respondsToSelector:@selector(tableView:tracksEventsForCell:atIndexPath:)]);
	if (delegateResponds) {
		
		NSInteger totalOfRows = 0;
		for (int section = 0; section < numberOfSections; section++)
			totalOfRows += ((NSArray *)sectionsRows[section]).count;
		
		/* Add tracking rect for each cell */
		cellsEvents = (unsigned int *)malloc(totalOfRows * sizeof(unsigned int));
		NSInteger section = 0, totalRow = 0;
		for (NSArray * sectionRows in sectionsRows) {
			NSInteger rowIndex = 0;// The row index of the current section
			for (TableViewCell * cell in sectionRows) {
				/* Ask the delegate before tracking */
				NSIndexPath * indexPath = [[NSIndexPath alloc] initWithSection:section row:rowIndex];
				TableViewCellEvent eventMask = [_delegate tableView:self tracksEventsForCell:cell atIndexPath:indexPath];
				cellsEvents[totalRow] = eventMask;
				if (eventMask > 0) {
					NSDictionary * userInfo = @{ kTrackedViewKey : cell, kIndexPathKey : indexPath };
					NSRect frame = NSMakeRect(0., 0., cell.frame.size.width, cell.frame.size.height);
					NSTrackingArea * trackingArea = [[NSTrackingArea alloc] initWithRect:frame
																				 options:(NSTrackingMouseEnteredAndExited | NSTrackingActiveInKeyWindow)
																				   owner:self
																				userInfo:userInfo];
					[cell addTrackingArea:trackingArea];
				}
				
				rowIndex++;
			}
			section++;
			totalRow++;
		}
	}
	
	isTrackingCells = YES;
}

- (void)stopTrackingCells
{
	for (NSArray * sectionRows in sectionsRows) {
		for (TableViewCell * cell in sectionRows) {
			NSArray * trackingAreasCopy = [cell.trackingAreas copy];
			for (NSTrackingArea * trackingArea in trackingAreasCopy)
				[cell removeTrackingArea:trackingArea];
		}
	}
	
	if (cellsEvents) free(cellsEvents);
	cellsEvents = NULL;
	
	isTrackingCells = NO;
}

#pragma mark - Size Updating Methods

- (CGFloat)heightForSection:(NSInteger)section
{
	BOOL showsClosureButton = showsClosureButtons[section];
	TableViewSectionState sectionState = sectionsState[section];
	if (showsClosureButton && sectionState == TableViewSectionStateClose) {/* If closed, return "kSectionHeight" */
		return kSectionHeight;
	} else {/* Else, if open, return the height of the section */
		return sectionsHeight[section];
	}
}

- (void)scrollPoint:(NSPoint)aPoint
{
	[super scrollPoint:aPoint];
	[self.documentView scrollPoint:aPoint];// Scroll on the document view, scrolling on view haven't any effect
}

- (void)reflectScrolledClipView:(NSClipView *)aClipView
{
	[super reflectScrolledClipView:aClipView];
	
	NSPoint offset = [[self contentView] bounds].origin;
	/* Find the section to show at the top */
	int topSection = 0;
	float sectionsTotalHeight = 0.;
	for (int section = 0; section < numberOfSections; section++) {
		sectionsTotalHeight += [self heightForSection:section];
		if (sectionsTotalHeight < offset.y) {
			topSection++;
		} else break;
	}
	
	/* Fix all section to the original position (hard way) */
	float y = 0.;
	for (int section = 0; section < numberOfSections; section++) {
		TableViewSection * sectionView = sectionsView[section];
		NSRect frame = sectionView.frame;
		frame.origin.y = y;
		sectionView.frame = frame;
		
		y += [self heightForSection:section];
	}
	
	/*
	 * Compute the offset when topsection is close to change (to not have an overlapsing effect)
	 * If the next-top section is closer than the height of a section, offset the current section to the top, else don't offset.
	 */
	
	/* Fix the position to the top section */
	if (topSection < sectionsView.count) {
		TableViewSection * sectionView = sectionsView[topSection];
		NSRect frame = sectionView.frame;
		
		CGFloat aboveTopSectionOffset = ((sectionsTotalHeight - offset.y) <= kSectionHeight)? (kSectionHeight - (sectionsTotalHeight - offset.y)) : 0.;
		frame.origin.y = ((offset.y < 0)? 0. : offset.y) - aboveTopSectionOffset;
		
		sectionView.frame = frame;
	}
}

- (void)setFrameSize:(NSSize)newSize
{
	if ([_delegate respondsToSelector:@selector(tableView:willResize:)])
		[_delegate tableView:self willResize:newSize];
	
	[super setFrameSize:newSize];
	
	if ([_delegate respondsToSelector:@selector(tableView:shouldInvalidateContentLayoutForSize:)] &&
		[_delegate tableView:self shouldInvalidateContentLayoutForSize:newSize]) {
		[self invalidateContentLayout];
	} else {
		[self updateContentLayout];
	}
	
	if ([_delegate respondsToSelector:@selector(tableView:didResize:)])
		[_delegate tableView:self didResize:newSize];
}

#pragma mark - Layout Update Methods

- (void)invalidateContentLayout
{
	BOOL respondsToSelector = ([_dataSource respondsToSelector:@selector(tableView:rowHeightAtIndex:)]);
	
	NSInteger rowIndex = 0, row = 0;
	CGFloat _totalHeight = 0.;
	for (int section = 0; section < numberOfSections; section++) {
		row = 0;
		
		NSArray * sectionCells = (NSArray *)sectionsRows[section];
		
		CGFloat sectionHeight = kSectionHeight;
		
		TableViewSectionState sectionState = sectionsState[section];
		if (sectionState == TableViewSectionStateOpen) {// If section is open
			CGFloat y = _totalHeight + kSectionHeight;
			for (TableViewCell * cell in sectionCells) {
				
				CGFloat rowHeight = _rowHeight;
				if (respondsToSelector) {
					NSIndexPath * indexPath = [[NSIndexPath alloc] initWithSection:section row:row];
					rowHeight = [_dataSource tableView:self rowHeightAtIndex:indexPath];
				}
				rowsHeight[rowIndex] = (rowHeight + 1.);
				
				NSRect frame = cell.frame;
				frame.origin.y = y;
				frame.size.height = rowHeight;
				cell.frame = frame;
				
				y += (rowHeight + 1.);
				rowIndex++;
				row++;
				
				sectionHeight += (rowHeight + 1.);
			}
			
			sectionsHeight[section] = sectionHeight;
			
		} else {// Else, if section is closed
			/* Keep the rowIndex updated */
			rowIndex += sectionCells.count;
		}
		_totalHeight += sectionHeight;
	}
	
	if (placeholderLabel) {
		NSRect rect = self.contentView.documentRect;
		rect.origin = NSMakePoint(0., (int)(_totalHeight + ((rect.size.height - _totalHeight - 30.) / 2.)));
		rect.size.height = 30.;
		placeholderLabel.frame = rect;
	}
	
	NSSize size = ((NSView *)self.documentView).frame.size;
	[self.documentView setFrameSize:NSMakeSize(size.width, _totalHeight)];
	totalHeight = _totalHeight;
}

- (void)updateContentLayout
{
	NSInteger rowIndex = 0;
	CGFloat _totalHeight = 0.;
	for (int section = 0; section < numberOfSections; section++) {
		
		NSArray * sectionCells = (NSArray *)sectionsRows[section];
		CGFloat sectionHeight = [self heightForSection:section];
		
		if (sectionHeight > kSectionHeight) {// If section is open
			CGFloat y = _totalHeight + kSectionHeight;
			for (TableViewCell * cell in sectionCells) {
				NSRect frame = cell.frame;
				frame.origin.y = y;
				cell.frame = frame;
				
				y += rowsHeight[rowIndex];
				rowIndex++;
			}
		} else {// Else, if section is closed
			/* Keep the rowIndex updated */
			rowIndex += sectionCells.count;
		}
		
		_totalHeight += sectionHeight;
	}
	
	if (placeholderLabel) {
		NSRect rect = self.contentView.documentRect;
		rect.origin = NSMakePoint(0., (int)(_totalHeight + ((rect.size.height - _totalHeight - 30.) / 2.)));
		rect.size.height = 30.;
		placeholderLabel.frame = rect;
	}
	
	NSSize size = ((NSView *)self.documentView).frame.size;
	[self.documentView setFrameSize:NSMakeSize(size.width, _totalHeight)];
	totalHeight = _totalHeight;
}

- (void)update
{
	// @TODO: remove this method
	[self updateContentLayout];
}

#pragma mark - Rows Location Helper Methods

- (NSInteger)rowIndexForIndexPath:(NSIndexPath *)indexPath
{
	NSInteger rowIndex = 0;
	for (int section = 0; section < indexPath.section; section++)
		rowIndex += numberOfRows[section];
	return (rowIndex + indexPath.row);
}

- (TableViewCell *)cellAtIndexPath:(NSIndexPath *)indexPath
{
	if (!indexPath)// a nil indexPath return 0 for section and zero for row so check if the input indexPath is not nil
		return nil;
	
	NSUInteger section = indexPath.section;
	if (section < sectionsRows.count) {// Check "sectionsRows" bounds
		NSUInteger row = indexPath.row;
		NSArray * sectionRows = sectionsRows[section];
		if (row < sectionRows.count) {// Check "sectionRows" bounds
			return sectionRows[row];
		}
	}
	return nil;
}

- (NSIndexPath *)indexPathForCell:(TableViewCell *)cell
{
	for (int section = 0; section < numberOfSections; section++) {
		NSInteger row = [(NSArray *)sectionsRows[section] indexOfObject:cell];
		if (row != NSNotFound)
			return [NSIndexPath indexPathWithSection:section row:row];
	}
	return nil;
}

- (NSIndexPath *)indexPathForCellAtPoint:(NSPoint)point
{
	/* fetch all sections and rows until find a row that match with "point" */
	CGFloat totalSectionsHeight = 0.;
	NSInteger currentRow = 0;
	for (int section = 0; section < numberOfSections; section++) {
		CGFloat sectionHeight = [self heightForSection:section];
		NSInteger rowCount = numberOfRows[section];
		if (totalSectionsHeight <= point.y && point.y < (totalSectionsHeight + sectionHeight)) {
			CGFloat currentHeight = totalSectionsHeight + kSectionHeight;
			for (int row = 0; row < rowCount; row++) {
				CGFloat rowHeight = rowsHeight[(currentRow + row)];
				if (currentHeight <= point.y && point.y < (currentHeight + rowHeight)) {
					return [NSIndexPath indexPathWithSection:section row:row];
				}
				currentHeight += rowHeight;
			}
		}
		totalSectionsHeight += sectionHeight;
		currentRow += rowCount;
	}
	return nil;
}

- (NSIndexPath *)indexPathForDragAtPoint:(NSPoint)point
{
	NSIndexPath * indexPath = [self indexPathForCellAtPoint:point];
	if (indexPath) {
		TableViewCell * cell = [self cellAtIndexPath:indexPath];
		CGFloat rowHeight = rowsHeight[(int)([self rowIndexForIndexPath:indexPath])];
		CGFloat offsetToMiddle = point.y - (cell.frame.origin.y + rowHeight / 2.);
		
		if (offsetToMiddle > 0) { // If "offsetToMiddle" is positive, we are dragging under the middle of the cell, add one to "indexPath.row"
			return [NSIndexPath indexPathWithSection:indexPath.section row:(indexPath.row + 1)];
		}
	} else {
		
		/* Check if we are in a section header */
		NSInteger section = -1, index = 0;// "section" is the index of the sectionView, "-1" if the drag is not into a sectionView
		for (TableViewSection * sectionView in sectionsView) {
			if (NSPointInRect(point, sectionView.frame)) {
				section = index;
			}
			index++;
		}
		
		if (section == -1)
			section = (numberOfSections - 1);
		
		/* Create an indexPath under the last row into the last section */
		indexPath = [NSIndexPath indexPathWithSection:section
												  row:numberOfRows[section]];
	}
	return indexPath;
}

- (NSInteger)sectionAtPoint:(NSPoint)point
{
	CGFloat totalSectionsHeight = 0.;
	for (int section = 0; section < numberOfSections; section++) {
		CGFloat sectionHeight = [self heightForSection:section];
		if (totalSectionsHeight <= point.y && point.y < (totalSectionsHeight + sectionHeight)) {
			return section;
		}
		totalSectionsHeight += sectionHeight;
	}
	return -1;
}

- (NSRect)rectForSection:(NSInteger)section includeSectionHeader:(BOOL)withSection
{
	if (section < 0)
		return NSZeroRect;
	
	float y = (withSection)? 0.: kSectionHeight;
	for (int i = 0; i < section; i++) {
		y += [self heightForSection:i];
	}
	return CGRectMake(0., y, ((NSView *)self.documentView).frame.size.width, [self heightForSection:section] - ((withSection)? 0.: kSectionHeight));
}

#pragma mark - Mouse Events

- (NSPoint)convertLocationFromWindow:(NSPoint)locationInWindow
{
	NSPoint location = [self convertPointToBase:locationInWindow];
	NSPoint offset = [[self contentView] bounds].origin;
	location.x += offset.x;
	location.y += offset.y;
	return location;
}

- (void)mouseEntered:(NSEvent *)theEvent
{
	NSDictionary * userInfo = (NSDictionary *)theEvent.userData;
	NSView * view = userInfo[kTrackedViewKey];
	if ([view isKindOfClass:[TableViewSection class]]) {
		if (sectionsEvents) {
			NSInteger section = [(NSNumber *)userInfo[kSectionKey] integerValue];
			if (sectionsEvents[section] & TableViewCellEventMouseEntered) {
				if ([_delegate respondsToSelector:@selector(tableView:didReceiveEvent:forSection:)])
					[_delegate tableView:self didReceiveEvent:TableViewCellEventMouseEntered forSection:section];
			}
		}
	} else {
		if (cellsEvents) {
			NSIndexPath * indexPath = userInfo[kIndexPathKey];
			NSInteger rowIndex = [self rowIndexForIndexPath:indexPath];
			if (cellsEvents[rowIndex] & TableViewCellEventMouseEntered &&
				[_delegate respondsToSelector:@selector(tableView:didReceiveEvent:forCell:atIndexPath:)]) {
				[_delegate tableView:self didReceiveEvent:TableViewCellEventMouseEntered forCell:(TableViewCell *)view atIndexPath:indexPath];
			}
		}
	}
}

- (void)mouseExited:(NSEvent *)theEvent
{
	NSDictionary * userInfo = (NSDictionary *)theEvent.userData;
	NSView * view = userInfo[kTrackedViewKey];
	if ([view isKindOfClass:[TableViewSection class]]) {
		if (sectionsEvents) {
			NSInteger section = [(NSNumber *)userInfo[kSectionKey] integerValue];
			if (sectionsEvents[section] & TableViewCellEventMouseExited) {
				if ([_delegate respondsToSelector:@selector(tableView:didReceiveEvent:forSection:)])
					[_delegate tableView:self didReceiveEvent:TableViewCellEventMouseExited forSection:section];
			}
		}
	} else {
		if (cellsEvents) {
			NSIndexPath * indexPath = userInfo[kIndexPathKey];
			NSInteger rowIndex = [self rowIndexForIndexPath:indexPath];
			if (cellsEvents[rowIndex] & TableViewCellEventMouseExited &&
				[_delegate respondsToSelector:@selector(tableView:didReceiveEvent:forCell:atIndexPath:)]) {
				[_delegate tableView:self didReceiveEvent:TableViewCellEventMouseExited forCell:(TableViewCell *)view atIndexPath:indexPath];
			}
		}
	}
}

- (void)selectCellAtIndexPath:(NSIndexPath *)newIndexPath
{
	/* Don't do anything if user try to re-select the same cell */
	/*
																   if (newIndexPath.section == selectedIndexPath.section && newIndexPath.row == selectedIndexPath.row)
																   return;
																   */
	
	/* Ask the delegate if the cell can be selected, if no delegate available, select the cell by default */
	TableViewCell * newCell = [self cellAtIndexPath:newIndexPath];
	if (newCell) {
		BOOL delegateResponds = [_delegate respondsToSelector:@selector(tableView:shouldSelectCell:atIndexPath:)];
		if ((delegateResponds && [_delegate tableView:self shouldSelectCell:newCell atIndexPath:newIndexPath]) || !delegateResponds) {
			
			/* Deselect the current selected one */
			if (selectedIndexPath) {
				TableViewCell * oldCell = [self cellAtIndexPath:selectedIndexPath];
				oldCell.selected = NO;
			}
			
			selectedIndexPath = newIndexPath;
			
			/* Select the new one */
			newCell.selected = YES;
			
			if ([_delegate respondsToSelector:@selector(tableView:didSelectCell:atIndexPath:)])
				[_delegate tableView:self didSelectCell:newCell atIndexPath:newIndexPath];
		}
	}
}

- (void)doubleClicOnCellAtIndexPath:(NSIndexPath *)indexPath
{
	TableViewCell * cell = [self cellAtIndexPath:indexPath];
	if ([_delegate respondsToSelector:@selector(tableView:didDoubleClickOnCell:atIndexPath:)]) {
		[_delegate tableView:self didDoubleClickOnCell:cell atIndexPath:indexPath];
	}
}

- (void)mouseDown:(NSEvent *)theEvent
{
	NSPoint location = [self convertLocationFromWindow:[theEvent locationInWindow]];
	NSIndexPath * indexPath = [self indexPathForCellAtPoint:location];
	
	/* Select the cell even if the user double-click on row */
	if (theEvent.clickCount == 1) {
		[self selectCellAtIndexPath:indexPath];
	} else if (theEvent.clickCount > 1) {
		[self doubleClicOnCellAtIndexPath:indexPath];
	}
}

- (void)menuDidClose:(NSMenu *)menu
{
	/* Don't use "-[TableView deselectSection:]" because "selectedSection" could be read by the delegate to know the select section */
	if (selectedSection != -1)
		((TableViewSection *)sectionsView[selectedSection]).selected = NO;
	
	menu.delegate = nil;
}

- (NSMenu *)menuForEvent:(NSEvent *)theEvent
{
	NSMenu * menu = nil;
	NSPoint location = [self convertLocationFromWindow:[theEvent locationInWindow]];
	NSIndexPath * indexPath = [self indexPathForCellAtPoint:location];
	if (indexPath) {// It's a cell
		if ([_delegate respondsToSelector:@selector(rightClickMenuForTableView:forCellAtIndexPath:)]) {
			NSIndexPath * indexPath = [self indexPathForCellAtPoint:location];
			menu = [_delegate rightClickMenuForTableView:self forCellAtIndexPath:indexPath];
			
			if (menu)// If the delegate returns a menu, select the row
				[self selectRowAtIndexPath:indexPath];
		}
	} else {// It's not a cell, it could be a section
		NSInteger section = [self sectionAtPoint:location];
		if (section != -1) {// We've hit a section
			if ([_delegate respondsToSelector:@selector(rightClickMenuForTableView:forSection:)]) {
				menu = [_delegate rightClickMenuForTableView:self forSection:section];
				
				[self deselectRowAtIndexPath:selectedIndexPath];
				[self deselectSelectedSection];
				
				if (menu) {// If the delegate returns a menu, select the section
					menu.delegate = self;// Set the delegate to be notify by "menuDidClose"
					selectedSection = section;
					[self selectSection:section];
				}
			}
		}
	}
	
	return menu;
}

- (NSDragOperation)draggingUpdated:(id < NSDraggingInfo >)sender
{
	if (self.window.attachedSheet) // Don't allow content to be dragged if a sheet is shown
		return NSDragOperationNone;
	
	const CGFloat kAutoscrollOffset = 20.;
	NSPoint point = [sender draggingLocation];
	NSRect frame = self.frame;
	NSPoint offset = self.contentView.bounds.origin;
	
	if (0 <= (point.y - frame.origin.y) && (point.y - frame.origin.y) <= kAutoscrollOffset) {
		offset.y += 2.;
		[[self documentView] scrollPoint:offset];//[[self documentView] scrollPoint:NSMakePoint(0., frame.origin.y + point.y + kAutoscrollOffset)];
	} else if (0 <= ((frame.origin.y + frame.size.height) - point.y) &&
			   ((frame.origin.y + frame.size.height) - point.y) <= kAutoscrollOffset) {
		offset.y -= 2.;
		[[self documentView] scrollPoint:offset];//[[self documentView] scrollPoint:NSMakePoint(0., point.y + (frame.origin.y + frame.size.height))];
	}
	
	if (!draggingView) {
		NSRect rect = NSMakeRect(0., 0., self.bounds.size.width, 3.);
		draggingView = [[_TableViewSelectionView alloc] initWithFrame:rect];
		[(NSView *)self.documentView addSubview:draggingView];
	}
	
	NSPoint location = [self convertLocationFromWindow:[sender draggingLocation]];
	
	/* Check if we are in a section header */
	NSInteger section = -1, index = 0;// "section" is the index of the sectionView, "-1" if the drag is not into a sectionView
	for (TableViewSection * sectionView in sectionsView) {
		if (NSPointInRect(location, sectionView.frame)) {
			section = index;
		}
		index++;
	}
	
	NSIndexPath * indexPath = nil;
	if (section > -1) {// If the drag is into the section header
		
		if ([self.delegate respondsToSelector:@selector(tableView:allowsDragOnSection:)]) {
			if (![self.delegate tableView:self allowsDragOnSection:section])
				return NO;
		}
		
		/* If the section is closed or empty, draw a line below the section header */
		NSInteger rowCount = numberOfRows[section];
		BOOL sectionClosed = (sectionsState[section] == TableViewSectionStateClose);
		if (rowCount == 0 || sectionClosed) {// If the row is empty OR closed, show a line under the section header
			TableViewSection * sectionView = sectionsView[section];
			CGFloat y = sectionView.frame.origin.y + sectionView.frame.size.height;
			NSRect rect = NSMakeRect(0., y - 2., self.bounds.size.width, 3.);
			draggingView.frame = rect;
			
		} else {
			// Get the frame from the bottom of the section header to the bottom of the section
			NSRect rect = [self rectForSection:section includeSectionHeader:NO];
			draggingView.frame = rect;
			[draggingView drawRectStroke:NSOffsetRect(rect, -rect.origin.x, -rect.origin.y)];
		}
		
		/* Select the section header */
		[self selectSection:section];
		
		/* If the drag is to the section header, pass to the delegate an indexPath with the current section and row = numberOfRowsInSection (for the row after the last row i.e. (numberOfRowsInSection - 1 (for the last row) + 1)) */
		indexPath = [NSIndexPath indexPathWithSection:section
												  row:rowCount];
	} else {// Else, the drag is into a row or below rows
		indexPath = [self indexPathForDragAtPoint:location];
		
		if ([self.delegate respondsToSelector:@selector(tableView:allowsDragOnCellAtIndexPath:)]) {
			if (![self.delegate tableView:self allowsDragOnCellAtIndexPath:indexPath])
				return NSDragOperationNone;
		}
		
		/* Remove the stroked rectangle when dragging into a section's header */
		[draggingView drawRectStroke:NSZeroRect];
		
		/* Deselect the section header (selected on drag on section header) */
		[self deselectSelectedSection];
		
		CGFloat y = 0;
		if (indexPath.row < numberOfRows[indexPath.section]) {
			y = [self cellAtIndexPath:indexPath].frame.origin.y;
		} else {
			TableViewCell * cell = [self cellAtIndexPath:[NSIndexPath indexPathWithSection:indexPath.section row:(indexPath.row - 1)]];
			y = cell.frame.origin.y + cell.frame.size.height;
		}
		
		NSRect rect = NSMakeRect(0., y - 2., self.bounds.size.width, 3.);
		draggingView.frame = rect;
	}
	
	NSArray * items = [[sender draggingPasteboard] pasteboardItems];
	NSDragOperation op = [sender draggingSourceOperationMask];
	return [self.delegate tableView:self dragOperationForItems:items proposedOperation:op atIndexPath:indexPath];
}

- (BOOL)prepareForDragOperation:(id < NSDraggingInfo >)sender
{
	if (self.window.attachedSheet) // Don't allow content to be dragged if a sheet is shown
		return NO;
	
	NSPoint location = [self convertLocationFromWindow:[sender draggingLocation]];
	NSIndexPath * indexPath = [self indexPathForDragAtPoint:location];
	
	NSArray * items = [[sender draggingPasteboard] pasteboardItems];
	return [self.delegate tableView:self shouldDragItems:items atIndexPath:indexPath];
}

- (BOOL)performDragOperation:(id < NSDraggingInfo >)sender
{
	[draggingView removeFromSuperview];
	draggingView = nil;
	
	NSPoint location = [self convertLocationFromWindow:[sender draggingLocation]];
	NSIndexPath * indexPath = [self indexPathForDragAtPoint:location];
	
	if (!indexPath) {
		NSInteger section = [self sectionAtPoint:location];
		
		/* If the drag is to the section header, show a rect under the section and passed to delegate a indexPath with the current section and row = numberOfRowsInSection (for the row after the last row i.e. (numberOfRowsInSection - 1 (for the last row) + 1)) */
		NSInteger rowCount = ((NSArray *)sectionsRows[section]).count;
		indexPath = [NSIndexPath indexPathWithSection:section
												  row:rowCount];
	}
	
	NSArray * pasteboardItems = [[sender draggingPasteboard] pasteboardItems];
	[self.delegate tableView:self didDragItems:pasteboardItems withDraggingInfo:sender atIndexPath:indexPath];
	
	return YES;
}

- (void)draggingExited:(id < NSDraggingInfo >)sender
{
	/* Remove the drag rectangle */
	[draggingView removeFromSuperview];
	draggingView = nil;
	
	/* Deselect the section header (selected on drag on section header) */
	[self deselectSelectedSection];
}

- (void)closureButtonDidClicked:(NSInteger)state forSectionView:(TableViewSection *)sectionView
{
	NSInteger section = [sectionsView indexOfObject:sectionView];
	TableViewSectionState sectionState = (state == NSOffState)? TableViewSectionStateClose : TableViewSectionStateOpen;
	sectionsState[section] = sectionState;
	
	NSArray * sectionCells = (NSArray *)sectionsRows[section];
	for (TableViewCell * cell in sectionCells) {
		/* If section closed (state == NSOffState), hide all rows from the section, else show cells (don't hide) */
		[cell setHidden:(state == NSOffState)];
	}
	[self updateContentLayout];
	
	if ([_delegate respondsToSelector:@selector(tableView:didChangeState:ofSection:)]) {
		[_delegate tableView:self didChangeState:sectionState ofSection:section];
	}
}

#pragma mark - Key Events

- (BOOL)performKeyEquivalent:(NSEvent *)theEvent
{
	/* Get the index path of the selected cell
	 * Increment (Down) or decrement (Up) the row part of the indexPath
	 * Check if the new selected cell can be selected or if this is the last row of the section, in this case, jump to the next selectable cell
	 */
	
	/* @FIXME: "performKeyEquivalent" is called many times (2-3 times per key pressed)
	if (theEvent.charactersIgnoringModifiers.length == 1) {
		unichar keyChar = [theEvent.charactersIgnoringModifiers characterAtIndex:0];
		NSInteger offset = 0;
		
		if (keyChar == NSUpArrowFunctionKey) { offset--; }
		else if (keyChar == NSDownArrowFunctionKey) { offset++; }
		
		if (offset != 0) {
			NSInteger rows = numberOfRows[selectedIndexPath.section];
			NSInteger newSection = selectedIndexPath.section;
			NSInteger newRow = selectedIndexPath.row + offset;// @TODO: jump unselectable rows
			
			if (newRow < 0) { newSection--; newRow = (numberOfRows[newSection] - 1); }
			else if (newRow >= rows) { newSection++; newRow = 0; }
			
			if (newSection < 0) { newSection = 0; }
			else if (newSection >= numberOfSections) { newSection = (numberOfSections - 1); }
			
			NSIndexPath * newIndexPath = [NSIndexPath indexPathWithSection:newSection row:newRow];
			[self selectCellAtIndexPath:newIndexPath];
		}
	}
	*/
	
	if ([_delegate respondsToSelector:@selector(tableView:didReceiveKeyString:)]) {
		[_delegate tableView:self didReceiveKeyString:theEvent.charactersIgnoringModifiers];
	}
	
	return [super performKeyEquivalent:theEvent];
}

#pragma mark - NSTextField Delegate

- (BOOL)control:(NSControl *)control textShouldEndEditing:(NSText *)fieldEditor
{
	id sender = control.superview;
	if ([sender isKindOfClass:[TableViewSection class]]) {
		TableViewSection * sectionView = (TableViewSection *)sender;
		NSInteger section = [sectionsView indexOfObject:sectionView];
		if ([_delegate respondsToSelector:@selector(tableView:setString:forSection:)])
			[_delegate tableView:self setString:fieldEditor.string forSection:section];
		
	} else if ([sender isKindOfClass:[TableViewCell class]]) {
		TableViewCell * cell = (TableViewCell *)sender;
		NSIndexPath * indexPath = [self indexPathForCell:cell];
		if ([_delegate respondsToSelector:@selector(tableView:setString:forCellAtIndexPath:)])
			[_delegate tableView:self setString:fieldEditor.string forCellAtIndexPath:indexPath];
	}
	
	return YES;
}

@end
