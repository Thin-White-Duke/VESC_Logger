//
//  ViewController.h
//  VESCLogger
//
//  Created by Ben Harraway on 17/03/2016.
//  Copyright © 2016 Gourmet Pixel. All rights reserved.
//

#import <UIKit/UIKit.h>

@import CoreBluetooth;
@import QuartzCore;

#import "VescController.h"
#import "DataGraphView.h"

// Adafruit UART friend
// https://learn.adafruit.com/introducing-the-adafruit-bluefruit-le-uart-friend/uart-service

#define UART_SERVICE_UUID @"6E400001-B5A3-F393-E0A9-E50E24DCCA9E"
#define RX_CHARACTERISTIC_UUID @"6E400003-B5A3-F393-E0A9-E50E24DCCA9E"
#define TX_CHARACTERISTIC_UUID @"6E400002-B5A3-F393-E0A9-E50E24DCCA9E"
#define DEVICE_INFO_UUID @"180A"
#define HARDWARE_REVISION_UUID @"2A27"

@interface ViewController : UIViewController <CBCentralManagerDelegate, CBPeripheralDelegate> {
    UILabel *lblVESCStatus;
    UILabel *lblAppStatus;
    UIButton *btnStartStopRecording;
    
    UILabel *lblVescBattery;
    
    BOOL isRecording;
    
    DataGraphView *aDataGraphView;
    int currentGraphVariable;
    
    UIButton *btnStartControlMode;
    UIView *controlModeView;
    UISlider *sliderVescControl;
    NSTimer *controlModeTimer;
}


@property (nonatomic, retain) VescController *aVescController;

@property (nonatomic, strong) CBCentralManager *centralManager;
@property (nonatomic, strong) CBPeripheral     *UARTPeripheral;

@property (nonatomic, strong) CBCharacteristic *txCharacteristic;
@property (nonatomic, strong) CBCharacteristic *rxCharacteristic;

@property (nonatomic, strong) NSMutableArray *dataArray;

@end

