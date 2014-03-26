//
//  TableViewSection.h
//  TableView
//
//  Created by Max on 12/10/12.
//  Copyright (c) 2012 Lis@cintosh. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class TableViewSection;
@protocol TableViewSectionClosureButtonProtocol <NSObject>

- (void)closureButtonDidClicked:(NSInteger)state forSectionView:(TableViewSection *)sectionView;

@end

@interface TableViewSectionTextField : NSTextField
@end

@interface TableViewSection : NSView
{
	/*
	NSButton * closureButton;
	NSTextField * textField;
	*/
	
	NSMutableArray * targets;
}

@property (nonatomic, readonly) NSButton * closureButton;
@property (nonatomic, readonly) TableViewSectionTextField * textField;

@property (nonatomic, strong) NSString * title;
@property (nonatomic, assign) BOOL showsClosureButton;

@property (nonatomic, assign, getter = isEditable) BOOL editable;

@property (nonatomic, assign) BOOL selected;

- (void)addTargetForClosureButton:(id <TableViewSectionClosureButtonProtocol>)target;

@end
