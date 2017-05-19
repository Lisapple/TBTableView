//
//  TableViewCell.m
//  TableView
//
//  Created by Max on 11/10/12.
//  Copyright (c) 2012 Lis@cintosh. All rights reserved.
//

#import "TableViewCell.h"

@implementation TableViewCellImageView

- (BOOL)acceptsFirstResponder
{
	return YES;
}

- (BOOL)becomeFirstResponder
{
	return YES;
}

- (NSMenu *)menuForEvent:(NSEvent *)theEvent
{
	/* The superView is the tableViewCell */
	return [self.superview menuForEvent:theEvent];
}

@end

@implementation TableViewCellTextField

- (BOOL)acceptsFirstResponder
{
	return YES;
}

- (BOOL)becomeFirstResponder
{
	return YES;
}

- (NSMenu *)menuForEvent:(NSEvent *)theEvent
{
	/* The superView is the tableViewCell */
	return [self.superview menuForEvent:theEvent];
}

@end

@implementation TableViewCell

- (instancetype)initWithStyle:(TableViewCellStyle)cellStyle reusableIdentifier:(NSString *)cellID
{
	NSRect frame = NSMakeRect(0., 0., 100., 17.);
	if ((self = [super initWithFrame:frame])) {
		style = cellStyle;
		reuseIdentifier = [cellID copy];
		
		frame = NSMakeRect(4., 2., 24., 14.);/* 4px margin + 24px width */
		_imageView = [[TableViewCellImageView alloc] initWithFrame:frame];
		[_imageView setEditable:NO];
		_imageView.autoresizingMask = (NSViewHeightSizable);
		[_imageView setHidden:YES];// Hidden by default
		[self addSubview:_imageView];
		
		const NSInteger height = 16.;
		frame = NSMakeRect(10. /*4. * 2. + 24.*/, (int)(self.frame.size.height - height) / 2.,
						   self.frame.size.width - (2. * 4. + 24.) - 20., height);
		_textField = [[TableViewCellTextField alloc] initWithFrame:frame];
		_textField.cell.controlSize = NSMiniControlSize;
		_textField.bezelStyle = NSTextFieldSquareBezel;
		[_textField setBezeled:NO];
		[_textField setBordered:NO];
		_textField.drawsBackground = NO;
		[_textField setEditable:NO];
		_textField.backgroundColor = [NSColor whiteColor];
		_textField.autoresizingMask = (NSViewWidthSizable | NSViewMinYMargin | NSViewMaxYMargin);
		[self addSubview:_textField];
		
		self.selectedBackgroundColor = [NSColor lightGrayColor];
		
		selectionAlphaValue = 1.;
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

- (BOOL)becomeFirstResponder
{
	return YES;
}

- (void)setTitle:(NSString *)title
{
	_title = title;
	if (title) {
		self.attributedTitle = nil;
		_textField.stringValue = title;
	}
}

- (void)setAttributedTitle:(NSAttributedString *)attributedTitle
{
	_attributedTitle = attributedTitle;
	if (attributedTitle) {
		self.title = nil;
		_textField.attributedStringValue = attributedTitle;
	}
}

- (void)setImage:(NSImage *)image
{
	_image = image;
	
	_imageView.image = _image;
	
	_imageView.hidden = (image == nil);
	NSRect rect = _textField.frame;
	rect.origin.x = (image == nil)? 10.: (4. * 2. + 24.); // Fix to 4px left if no image, else fix 4px to the imageView
	_textField.frame = rect;
}

- (void)setEditable:(BOOL)editable
{
	_editable = editable;
	_textField.editable = editable;
	_textField.bezeled = editable;
	_textField.drawsBackground = editable;
	_textField.font = (editable)? [NSFont systemFontOfSize:10.] : [NSFont systemFontOfSize:12.];
}

- (void)setBackgroundColor:(NSColor *)backgroundColor
{
	_backgroundColor = backgroundColor;
	
	[self setNeedsDisplay:YES];
}

- (void)setColorStyle:(TableViewCellBackgroundColorStyle)colorStyle
{
	if (colorStyle != _colorStyle) {
		 _backgroundColor = nil;
		 backgroundGradient = nil;
		
		switch (colorStyle) {
			default:
			case TableViewCellBackgroundColorStyleWhite: {
				_backgroundColor = [NSColor whiteColor];
				break;
			}
			case TableViewCellBackgroundColorStyleGray: {
				_backgroundColor = [NSColor colorWithCalibratedWhite:(243. / 255.) alpha:1.];
				break;
			}
			case TableViewCellBackgroundColorStyleWhiteGradient: {
				backgroundGradient = [[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedWhite:0.9 alpha:1.]
																   endingColor:[NSColor whiteColor]];
				break;
			}
			case TableViewCellBackgroundColorStyleGrayGradient: {
				backgroundGradient = [[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedWhite:0.9 alpha:1.]
																   endingColor:[NSColor colorWithCalibratedWhite:0.8 alpha:1.]];
				break;
			}
			case TableViewCellBackgroundColorStyleSystemTint: {
				NSColor * systemTintColor = [NSColor colorForControlTint:[NSColor currentControlTint]];
				_backgroundColor = systemTintColor;
				break;
			}
			case TableViewCellBackgroundColorStyleSystemTintGradient: {
				NSColor * systemTintColor = [NSColor colorForControlTint:[NSColor currentControlTint]];
				backgroundGradient = [[NSGradient alloc] initWithStartingColor:[systemTintColor highlightWithLevel:0.2]
																   endingColor:[systemTintColor shadowWithLevel:0.2]];
				break;
			}
		}
		_colorStyle = colorStyle;
	}
}

- (void)setSelectedColorStyle:(TableViewCellSelectedColorStyle)selectedColorStyle
{
	if (selectedColorStyle != _selectedColorStyle) {
		NSColor * highlightColor = [NSColor selectedControlColor];
		switch (selectedColorStyle) {
			default:
			case TableViewCellSelectedColorDefault:
				_selectedBackgroundColor = highlightColor;
				break;
			case TableViewCellSelectedColorDefaultGradient: {
				selectedBackgroundGradient = [[NSGradient alloc] initWithStartingColor:[highlightColor shadowWithLevel:0.1]
																		   endingColor:[highlightColor shadowWithLevel:0.2]];
				
				NSColor * inactiveColor = [NSColor secondarySelectedControlColor];
				inactiveSelectedBackgroundGradient = [[NSGradient alloc] initWithStartingColor:inactiveColor
																				   endingColor:[inactiveColor shadowWithLevel:0.1]];
				break;
			}
		}
		_selectedColorStyle = selectedColorStyle;
	}
}

- (void)setSelected:(BOOL)selected
{
	_selected = selected;
	
	_imageView.image = (selected)? _selectedImage : _image;
	
	[self setNeedsDisplay:YES];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
	__block BOOL selectedState = selected;
	selectionAlphaValue = (selected)? 0. : 1.;
	[BlockTimer performBlock:^{
		float delta = 1. / 10.;
		selectionAlphaValue += (selected)? delta : -delta;
		[self setNeedsDisplay:YES];
	}
			   numberOfTimes:10
					interval:.25
		   completionHandler:^{
			   _selected = selectedState;
			   selectionAlphaValue = 1.;
			   [self setNeedsDisplay:YES];
		   }];
}

- (void)drawRect:(NSRect)dirtyRect
{
	// @TODO: Profile with cached image from gradient
	if (_selected) {
		if (selectedBackgroundGradient) {
			
			[_backgroundColor setFill];
			NSRectFill(dirtyRect);
			
			CGContextRef context = [NSGraphicsContext currentContext].graphicsPort;
			CGContextSetAlpha(context, selectionAlphaValue);
			
			// @TODO: use CGContextDrawLinearGradient instead => check performance difference
			(self.window.isKeyWindow)? [selectedBackgroundGradient drawInRect:dirtyRect angle:90.]/* Start at lower-left */ : [inactiveSelectedBackgroundGradient drawInRect:dirtyRect angle:90.];
			
			CGContextSetAlpha(context, 1.);
			
		} else {
			(self.window.isKeyWindow)? [_selectedBackgroundColor setFill] : [[NSColor colorWithCalibratedWhite:0.75 alpha:1.] setFill];
			NSRectFill(dirtyRect);
		}
		
		if (!textColor) {
			textColor = [self.textField.textColor copy];
		}
		
		self.textField.textColor = [NSColor whiteColor];
		
	} else {
		if (backgroundGradient) {
			[backgroundGradient drawInRect:self.bounds angle:90.];// Start at lower-left
		} else if (_backgroundColor) {
			[_backgroundColor setFill];
			NSRectFill(dirtyRect);
		}
		
		self.textField.textColor = textColor ?: [NSColor blackColor];
	}
}

- (NSMenu *)menuForEvent:(NSEvent *)theEvent
{
	/* The superView of the cell is the scrollView's documentView, the superView of the documentView is the clipView and the superView of the clipView is the scrollView */
	return [self.superview.superview.superview menuForEvent:theEvent];
}

@end
