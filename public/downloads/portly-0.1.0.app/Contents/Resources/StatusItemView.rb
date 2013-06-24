#
#  StatusItemView.rb
#  port
#
#  Created by Kelly Martin on 3/5/13.
#  Copyright 2013 Kelly Martin. All rights reserved.
#


class StatusItemView

    attr_accessor :image
    attr_accessor :alternateImage
    attr_accessor :statusItem
    attr_accessor :isHighlighted
    
    attr_accessor :action
    attr_accessor :target
    
    def initWithStatusItem(status_item)
        itemWidth = status_item.length
        itemHeight = NSStatusBar.systemStatusBar.thickness;
        itemRect = NSMakeRect(0.0, 0.0, itemWidth, itemHeight)
    end
    
    #    (void)drawRect:(NSRect)dirtyRect
    # {
	# [self.statusItem drawStatusBarBackgroundInRect:dirtyRect withHighlight:self.isHighlighted];
    
    #NSImage *icon = self.isHighlighted ? self.alternateImage : self.image;
    #NSSize iconSize = [icon size];
    #NSRect bounds = self.bounds;
    #CGFloat iconX = roundf((NSWidth(bounds) - iconSize.width) / 2);
    #CGFloat iconY = roundf((NSHeight(bounds) - iconSize.height) / 2);
    #NSPoint iconPoint = NSMakePoint(iconX, iconY);
    #
	#[icon drawAtPoint:iconPoint fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
    #}

end