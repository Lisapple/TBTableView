//
//  TableViewCell.h
//  TableView
//
//  Created by Max on 11/10/12.
//  Copyright (c) 2012 Lis@cintosh. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "BlockTimer.h"

@interface TableViewCellImageView : NSImageView
@end

@interface TableViewCellTextField : NSTextField
@end

typedef NS_ENUM(NSUInteger, TableViewCellStyle) {
	TableViewCellStyleDefault
};

typedef NS_ENUM(NSUInteger, TableViewCellBackgroundColorStyle) {
	TableViewCellBackgroundColorStyleWhite = 1,
	TableViewCellBackgroundColorStyleGray,
	TableViewCellBackgroundColorStyleWhiteGradient,
	TableViewCellBackgroundColorStyleGrayGradient,
	
	TableViewCellBackgroundColorStyleSystemTint,
	TableViewCellBackgroundColorStyleSystemTintGradient
};

typedef NS_ENUM(NSUInteger, TableViewCellSelectedColorStyle) {
	TableViewCellSelectedColorDefault,
	TableViewCellSelectedColorDefaultGradient
};

@interface TableViewCell : NSView
{
	TableViewCellStyle style;
	NSString * reuseIdentifier;
	
	NSColor * textColor;
	
	/*
	TableViewCellImageView * imageView;
	TableViewCellTextField * textField;
	*/
	
	NSGradient * backgroundGradient;
	NSGradient * selectedBackgroundGradient, * inactiveSelectedBackgroundGradient;
	
	float selectionAlphaValue;
}

@property (nonatomic, readonly) NSImageView * imageView;
@property (nonatomic, readonly) NSTextField * textField;

@property (nonatomic, strong) NSString * title;
@property (nonatomic, strong) NSImage * image, * selectedImage;

@property (nonatomic, assign, getter = isEditable) BOOL editable;

@property (nonatomic, copy) NSColor * backgroundColor, * selectedBackgroundColor;
@property (nonatomic, assign, getter = isSelected) BOOL selected;

@property (nonatomic, assign) TableViewCellBackgroundColorStyle colorStyle;
@property (nonatomic, assign) TableViewCellSelectedColorStyle selectedColorStyle;

- (instancetype)initWithFrame:(NSRect)frameRect UNAVAILABLE_ATTRIBUTE;
- (instancetype)initWithCoder:(NSCoder *)coder UNAVAILABLE_ATTRIBUTE;
- (instancetype)initWithStyle:(TableViewCellStyle)cellStyle reusableIdentifier:(NSString *)cellID NS_DESIGNATED_INITIALIZER;

- (void)setSelected:(BOOL)selected animated:(BOOL)animated;

@end
