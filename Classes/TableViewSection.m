//
//  TableViewSection.m
//  TableView
//
//  Created by Max on 12/10/12.
//  Copyright (c) 2012 Lis@cintosh. All rights reserved.
//

#import "TableViewSection.h"

@implementation TableViewSectionTextField

- (NSMenu *)menuForEvent:(NSEvent *)theEvent
{
	/* The superView is the tableViewCell */
	return [self.superview menuForEvent:theEvent];
}

@end

@implementation TableViewSection

@synthesize closureButton = _closureButton, textField = _textField;
@synthesize title = _title, showsClosureButton = _showsClosureButton;
@synthesize editable = _editable;
@synthesize selected = _selected;

- (instancetype)initWithFrame:(NSRect)frame
{
    if ((self = [super initWithFrame:frame])) {
		/* Add the closureButton but hide it and don't change the position of "textField" */
		NSRect frame = NSMakeRect(10., (int)(self.frame.size.height - 13.) / 2., 13., 13.);
		_closureButton = [[NSButton alloc] initWithFrame:frame];
		_closureButton.title = @"";
		[_closureButton setButtonType:NSOnOffButton];
		_closureButton.bezelStyle = NSDisclosureBezelStyle;
		_closureButton.state = NSOnState;
		[_closureButton setHidden:YES];
		[self addSubview:_closureButton];
		
		_closureButton.target = self;
		_closureButton.action = @selector(closureButtonDidClicked:);
		
		float height = 16., margin = 10.;
        frame = NSMakeRect(margin, (int)((self.frame.size.height - height) / 2.) + 1,
						   self.frame.size.width - (2. * margin), height);
		_textField = [[TableViewSectionTextField alloc] initWithFrame:frame];
		_textField.cell.controlSize = NSMiniControlSize;
		_textField.textColor = [NSColor darkGrayColor];
		_textField.bezelStyle = NSTextFieldSquareBezel;
		[_textField setBezeled:NO];
		[_textField setBordered:NO];
		_textField.drawsBackground = NO;
		_textField.backgroundColor = [NSColor whiteColor];
		[_textField setEditable:NO];
		_textField.autoresizingMask = (NSViewWidthSizable | NSViewMinYMargin | NSViewMaxYMargin);
		[self addSubview:_textField];
    }
    
    return self;
}

- (BOOL)acceptsFirstResponder
{
	return YES;
}

- (BOOL)becomeFirstResponder
{
	return YES;
}

- (void)setShowsClosureButton:(BOOL)show
{
	_closureButton.hidden = !show;
	NSRect frame = _textField.frame;
	frame.origin.x = (show)? (10. + 13. + 4.): 10.;
	_textField.frame = frame;
	
	_showsClosureButton = show;
}

- (void)closureButtonDidClicked:(id)sender
{
	for (NSObject <TableViewSectionClosureButtonProtocol> * target in targets) {
		if ([target respondsToSelector:@selector(closureButtonDidClicked:forSectionView:)])
			[target closureButtonDidClicked:_closureButton.state forSectionView:self];
	}
}

- (void)addTargetForClosureButton:(id)target
{
	if (!targets) {
		targets = [[NSMutableArray alloc] initWithCapacity:3];
	}
	
	if (target)
		[targets addObject:target];
}

- (void)setTitle:(NSString *)title
{
	_title = title;
	
	_textField.stringValue = _title;
}

- (void)setEditable:(BOOL)editable
{
	_editable = editable;
	_textField.editable = editable;
	_textField.bezeled = editable;
	_textField.drawsBackground = editable;
	_textField.font = (editable)? [NSFont systemFontOfSize:10.] : [NSFont systemFontOfSize:12.];
}

- (void)setSelected:(BOOL)selected
{
	_selected = selected;
	_textField.textColor = (_selected)? [NSColor whiteColor] : [NSColor darkGrayColor];
	[self setNeedsDisplay:YES];
}

- (BOOL)isOpaque
{
	return NO;
}

void RectRoundedFill(CGRect rect, float radius);
void RectRoundedFill(CGRect rect, float radius)
{
	CGContextRef context = [NSGraphicsContext currentContext].graphicsPort;
	
	radius = MIN(radius, rect.size.height / 2.);
	float x = rect.origin.x, y = rect.origin.y, width = rect.size.width, height = rect.size. height;
	CGContextBeginPath(context);
	CGContextMoveToPoint(context, x, radius);
	CGContextAddArcToPoint(context, x, y, x + radius, y, radius);
	CGContextAddArcToPoint(context, x + width, y, x + width, radius, radius);
	CGContextAddArcToPoint(context, x + width, height + y, x + width - radius, height + y, radius);
	CGContextAddArcToPoint(context, x, height + y, x, height - radius, radius);
	CGContextClosePath(context);
	
	CGContextFillPath(context);
}

- (void)drawRect:(NSRect)dirtyRect
{
	[[NSColor colorWithDeviceWhite:1. alpha:0.8] setFill];
	NSRectFillUsingOperation(self.bounds, NSCompositeSourceOver);
	
	[[NSColor colorWithDeviceWhite:0.8 alpha:1.] setFill];
	CGRect rect = CGRectMake(0., 0., self.bounds.size.width, 1.);
	NSRectFill(rect);
	
	[[NSColor whiteColor] setFill];
	rect.origin.y = self.bounds.size.height - 1.;
	NSRectFill(rect);
	
	if (_selected) {
		[[NSColor grayColor] setFill];
		RectRoundedFill(CGRectMake(6., 2., dirtyRect.size.width - 2 * 6., dirtyRect.size.height - 2 * 2.), 100.);
	}
}

- (NSMenu *)menuForEvent:(NSEvent *)theEvent
{
	/* The superView of the cell is the scrollView's documentView, the superView of the documentView is the clipView and the superView of the clipView is the scrollView */
	return [self.superview.superview.superview menuForEvent:theEvent];
}

@end
