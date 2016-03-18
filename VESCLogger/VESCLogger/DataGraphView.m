//
//  DataGraphView.m
//  GoCat
//
//  Created by Ben Harraway on 01/07/2014.
//  Copyright (c) 2014 Ben Harraway. All rights reserved.
//
//  A generic graph for showing any kind of data.  1 data point.

#import "DataGraphView.h"

@implementation DataGraphView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        self.backgroundColor = [UIColor clearColor];
        
        _dataPointsArray = [[NSMutableArray alloc] init];
        
        lblTitle = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width-10, 25)];
        [lblTitle setBackgroundColor:[UIColor clearColor]];
        [lblTitle setFont:[lblMaxValue.font fontWithSize:14]];
        [lblTitle setTextColor:[UIColor blackColor]];
        [lblTitle setTextAlignment:NSTextAlignmentCenter];
        [self addSubview:lblTitle];
        
        lblMaxValue = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width-10, 25)];
        [lblMaxValue setBackgroundColor:[UIColor clearColor]];
        [lblMaxValue setFont:[lblMaxValue.font fontWithSize:14]];
        [lblMaxValue setTextColor:[UIColor blackColor]];
        [lblMaxValue setTextAlignment:NSTextAlignmentRight];
        [self addSubview:lblMaxValue];
        
        lblAverageValue = [[UILabel alloc] initWithFrame:CGRectMake(5, 0, self.frame.size.width-10, 25)];
        [lblAverageValue setBackgroundColor:[UIColor clearColor]];
        [lblAverageValue setFont:[lblAverageValue.font fontWithSize:14]];
        [lblAverageValue setTextColor:[UIColor blackColor]];
        [lblAverageValue setTextAlignment:NSTextAlignmentLeft];
        [self addSubview:lblAverageValue];
    }
    return self;
}

- (void) resetGraph {
    lblTitle.text = @"";
    lblMaxValue.text = @"";
    lblAverageValue.text = @"";
    highlightLocationPointIndex = 0;
}

- (void) viewLoggerData:(NSArray *)sessionLoggerData whichDataBit:(int)whichDataBit graphName:(NSString *)graphName {
    viewingDataBit = whichDataBit;
    
    // Input was the full Session Logger Data - filter it to our bit index
    thisBitLoggerData = [sessionLoggerData filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:[NSString stringWithFormat:@"inIndex == %@", [NSNumber numberWithInt:whichDataBit]]]];
    
    // Now sort it in timestamp order
    thisBitLoggerData = [[thisBitLoggerData mutableCopy] sortedArrayUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:YES]]];
    
    // Get the Value field and populate graph with that
    [self viewDataArray:[thisBitLoggerData valueForKey:@"value"]];
    _dataPointsName = graphName;
}

- (void) viewDataArray:(NSArray *)thisDataArray {
    [self resetGraph];
    _dataPointsArray = [thisDataArray mutableCopy];
    
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect {
    lblTitle.text = _dataPointsName;
    // Calculate max and average value
    double maxValue = 0;
    double avgValue = 0;
    for (NSNumber *an in _dataPointsArray) {
        avgValue += [an doubleValue];
        if ([an floatValue] > maxValue) maxValue = [an floatValue];
    }
    avgValue = avgValue/_dataPointsArray.count;
    [lblMaxValue setText:[NSString stringWithFormat:@"%0.2f max", maxValue]];
    [lblAverageValue setText:[NSString stringWithFormat:@"%0.2f avg", avgValue]];

    
    // Drawing code
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    // Draw axis lines
    CGContextSetRGBStrokeColor(context, 0.5, 0.5, 0.5, 0.5);
    CGFloat dashes[] = {1,1};
    CGContextSetLineDash(context, 0.0, dashes, 2);
    for (unsigned int i=40;i<self.bounds.size.height;i+=20) {
        CGContextMoveToPoint(context, 0, i);
        CGContextAddLineToPoint(context, self.bounds.size.width, i);
        CGContextStrokePath(context);
    }
    
    // Stop dashing
    CGContextSetLineDash(context, 0, NULL, 0);
    
    
    if (_dataPointsArray.count > 1) {
        // Distribute location points evenly across available space
        float xRatio = self.frame.size.width / _dataPointsArray.count+1;
        float yRatio = ((100/maxValue) * 0.8);    // *0.9 so we don't peak right at the top
        
        float xPos = 0;
        
        CGMutablePathRef strokePath = CGPathCreateMutable();
        CGMutablePathRef path = CGPathCreateMutable();
        
        // Now draw the actual graph lines
        CGContextBeginPath(context);
        CGContextSetLineWidth(context, 2.0);
        CGContextSetStrokeColorWithColor(context, [[UIColor blackColor] CGColor]);
        
        for (unsigned int i=0;i<_dataPointsArray.count;++i) {
            NSNumber *thisValue = [_dataPointsArray objectAtIndex:i];
            
            CGPoint drawPoint = CGPointMake(xPos, (self.frame.size.height-((yRatio * [thisValue floatValue]/100)*self.frame.size.height)));

//            NSLog(@"thisValue: %@ at %d. Render Y: %lf", thisValue, i, drawPoint.y);
            
            if (i==0) {
                CGPathMoveToPoint(strokePath, NULL, drawPoint.x, drawPoint.y);
                CGPathMoveToPoint(path, NULL, drawPoint.x, drawPoint.y);
            } else {
                CGPathAddLineToPoint(strokePath, NULL, drawPoint.x, drawPoint.y);
                CGPathAddLineToPoint(path, NULL, drawPoint.x, drawPoint.y);
            }
            
            xPos += xRatio;
        }
        
        // Because we want to fill the graph, complete the shape by drawing out of bounds the right, bottom, left lines....
        NSNumber *lastNumber = [_dataPointsArray lastObject];
        NSNumber *firstNumber = [_dataPointsArray firstObject];
        CGPathAddLineToPoint(strokePath, NULL, self.frame.size.width+5, 20+(self.frame.size.height-((yRatio * [lastNumber floatValue]/100)*self.frame.size.height)));
        CGPathAddLineToPoint(strokePath, NULL, self.frame.size.width+5, self.frame.size.height+5);
        CGPathAddLineToPoint(strokePath, NULL, -5, self.frame.size.height+5);
        CGPathAddLineToPoint(strokePath, NULL,  -5, 20+(self.frame.size.height-((yRatio * [firstNumber floatValue]/100)*self.frame.size.height)));
        
        
        CGPathAddLineToPoint(path, NULL, self.frame.size.width+5, 20+(self.frame.size.height-((yRatio * [lastNumber floatValue]/100)*self.frame.size.height)));
        CGPathAddLineToPoint(path, NULL, self.frame.size.width+5, self.frame.size.height+5);
        CGPathAddLineToPoint(path, NULL, -5, self.frame.size.height+5);
        CGPathAddLineToPoint(path, NULL,  -5, 20+(self.frame.size.height-((yRatio * [firstNumber floatValue]/100)*self.frame.size.height)));
        
        
        
        // setup the gradient
        CGFloat locations[2] = { 1.0, 0.0 };
        CGFloat components[8] = {
            0.5, 0.5, 0.7, 0.6,  // Start color
            0.5, 0.5, 0.8, 0.8   // End color
        };
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        CGGradientRef gradientFill = CGGradientCreateWithColorComponents (colorSpace, components, locations, 2);
        
        // setup gradient points
        CGRect pathRect = CGPathGetBoundingBox(path);
        CGPoint myStartPoint, myEndPoint;
        myStartPoint.x = CGRectGetMinX(pathRect);
        myStartPoint.y = CGRectGetMinY(pathRect);
        myEndPoint.x = CGRectGetMinX(pathRect);
        myEndPoint.y = CGRectGetMaxY(pathRect);
        
        // draw the gradient
        CGContextAddPath(context, path);
        CGContextSaveGState(context);
        CGContextClip(context);
        CGContextDrawLinearGradient (context, gradientFill, myStartPoint, myEndPoint, 0);
        CGContextRestoreGState(context);
        
        // draw the graph - problem here
        CGContextBeginPath(context);
        CGContextAddPath(context, strokePath);
        [[UIColor colorWithRed:104.0/255.0 green:104.0/255.0 blue:237.0/255.00 alpha:0.8] setStroke];
        CGContextSetLineWidth(context, 1.0);
        CGContextStrokePath(context);
        
        // User tapped graph, show vertical line on their tap point
        if (highlightLocationPointIndex) {
            CGContextSetRGBStrokeColor(context, 0.5, 0.5, 0.5, 0.5);
            CGFloat dashes[] = {1,1};
            CGContextSetLineDash(context, 0.0, dashes, 2);
            
            CGContextMoveToPoint(context, highlightLocationPointIndex, 20);
            CGContextAddLineToPoint(context, highlightLocationPointIndex, self.bounds.size.height);
            CGContextStrokePath(context);
            
            // Stop dashing
            CGContextSetLineDash(context, 0, NULL, 0);
            
            [highlightText drawAtPoint:CGPointMake(highlightLocationPointIndex+8, 40) withAttributes:@{NSFontAttributeName:[UIFont fontWithName:@"Avenir" size:11]}];
        }
        
        
        // cleanup
        CGColorSpaceRelease(colorSpace);
        CGGradientRelease(gradientFill);
        CGPathRelease(strokePath);
        CGPathRelease(path);
    }
}

- (void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    CGPoint touchPoint = [[touches anyObject] locationInView:self];
    [self calculateTouchedLocationPointIndex:touchPoint];
    
}
- (void) touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    CGPoint touchPoint = [[touches anyObject] locationInView:self];
    [self calculateTouchedLocationPointIndex:touchPoint];
}

// Map the touch point to the locationObject index
- (void) calculateTouchedLocationPointIndex:(CGPoint)touchPoint {
    if (_dataPointsArray.count > 0) {
        float renderedWidth = (self.frame.size.width / _dataPointsArray.count+1) * _dataPointsArray.count;
        int touchedLocationPointIndex = ceil(((_dataPointsArray.count+1)/renderedWidth) * touchPoint.x);
        
        touchedLocationPointIndex--;
        if (touchedLocationPointIndex < 0) touchedLocationPointIndex = 0;
        if (touchedLocationPointIndex > _dataPointsArray.count-1) touchedLocationPointIndex = _dataPointsArray.count-1;
        
        highlightText = [NSString stringWithFormat:@"%@", [_dataPointsArray objectAtIndex:touchedLocationPointIndex]];
        
        highlightLocationPointIndex = touchPoint.x;
        [self setNeedsDisplay];
    }
}


@end
