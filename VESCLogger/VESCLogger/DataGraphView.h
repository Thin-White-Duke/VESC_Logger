//
//  DataGraphView.h
//  GoCat
//
//  Created by Ben Harraway on 01/07/2014.
//  Copyright (c) 2014 Ben Harraway. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DataGraphView : UIView {
    UILabel *lblTitle;
    UILabel *lblAverageValue;
    UILabel *lblMaxValue;
    
    int highlightLocationPointIndex;
    NSString *highlightText;
    
    NSArray *thisBitLoggerData;
    int viewingDataBit;
}

@property (nonatomic, retain) NSString *dataPointsName;
@property (nonatomic, retain) NSMutableArray *dataPointsArray;

- (void) viewLoggerData:(NSArray *)sessionLoggerData whichDataBit:(int)whichDataBit graphName:(NSString *)graphName;
- (void) viewDataArray:(NSArray *)thisDataArray;

@end
