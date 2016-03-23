//
//  ViewController.m
//  VESCLogger
//
//  Created by Ben Harraway on 17/03/2016.
//  Copyright © 2016 Gourmet Pixel. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(newVESCvalues:) name:@"newVESCvalues" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(changeGraphVariable:) name:@"changeGraphVariable" object:nil];
    
    lblVESCStatus = [[UILabel alloc] initWithFrame:CGRectMake(0, 10, self.view.frame.size.width, 25)];
    [lblVESCStatus setFont:[UIFont fontWithName:@"Avenir" size:19]];
    [lblVESCStatus setText:@"Simple VESC Logger"];
    [lblVESCStatus setTextAlignment:NSTextAlignmentCenter];
    [self.view addSubview:lblVESCStatus];
    
    lblAppStatus = [[UILabel alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(lblVESCStatus.frame)+5, self.view.frame.size.width, 25)];
    [lblAppStatus setFont:[UIFont fontWithName:@"Avenir" size:12]];
    [lblAppStatus setText:@"Starting Bluetooth"];
    [lblAppStatus setTextAlignment:NSTextAlignmentCenter];
    [self.view addSubview:lblAppStatus];
    
    btnStartStopRecording = [[UIButton alloc] initWithFrame:CGRectMake((self.view.frame.size.width-200)/2, CGRectGetMaxY(lblAppStatus.frame)+15, 200, 50)];
    [btnStartStopRecording.titleLabel setFont:[UIFont fontWithName:@"Avenir" size:12]];
    btnStartStopRecording.layer.borderColor = [UIColor redColor].CGColor;
    btnStartStopRecording.layer.borderWidth = 1.0f;
    [btnStartStopRecording setTitle:@"Start Recording" forState:UIControlStateNormal];
    [btnStartStopRecording setTitle:@"Stop" forState:UIControlStateSelected];
    [btnStartStopRecording setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    [btnStartStopRecording addTarget:self action:@selector(startStopRecording) forControlEvents:UIControlEventTouchUpInside];
    btnStartStopRecording.alpha = 0;
    [self.view addSubview:btnStartStopRecording];
    
    aDataGraphView = [[DataGraphView alloc] initWithFrame:CGRectMake(20, CGRectGetMaxY(btnStartStopRecording.frame)+5, self.view.frame.size.width-40, self.view.frame.size.height-CGRectGetMaxY(btnStartStopRecording.frame)+5-20)];
    [self.view addSubview:aDataGraphView];

    UILongPressGestureRecognizer *tapGraph = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(changeGraph:)];
    [aDataGraphView addGestureRecognizer:tapGraph];

    lblVescBattery = [[UILabel alloc] initWithFrame:CGRectMake(0, lblVESCStatus.frame.origin.y, self.view.frame.size.width-10, 15)];
    [lblVescBattery setFont:[UIFont fontWithName:@"Avenir" size:12]];
    [lblVescBattery setText:@""];
    [lblVescBattery setTextAlignment:NSTextAlignmentRight];
    [self.view addSubview:lblVescBattery];
    

    isRecording = NO;
    
    // Init a VESC Controller
    _aVescController = [[VescController alloc] init];
    
    [_aVescController dataForGetValues:0 val:0];
    
    // Init Bluetooth
    _centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];

    // Test Stuff
    currentGraphVariable = 4; // 4 = RPM
    aDataGraphView.dataPointsName = [measureNames objectAtIndex:currentGraphVariable];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) UART_Ready {
    [lblAppStatus setText:@"Bluetooth OK and UART Ready"];
    [UIView animateWithDuration:0.2 animations:^(void){
        btnStartStopRecording.alpha=1;
    }];
    
    [self performSelector:@selector(doGetValues) withObject:nil afterDelay:0.3];
}

- (void) startStopRecording {
    if (!isRecording) {
        [self startRecording];
    } else {
        [self stopRecording];
    }

}

- (void) startRecording {
    isRecording = YES;
    btnStartStopRecording.selected = YES;
    _dataArray = [[NSMutableArray alloc] init];
    
    [self doGetValues];
}

- (void) stopRecording {
    isRecording = NO;
    btnStartStopRecording.selected = NO;
}

- (void) doGetValues {
    NSLog(@"Get Values");
    NSData *dataToSend = [_aVescController dataForGetValues:COMM_GET_VALUES val:0];
    if (dataToSend && _txCharacteristic) [_UARTPeripheral writeValue:dataToSend forCharacteristic:_txCharacteristic type:CBCharacteristicWriteWithResponse];
    
    if (isRecording) [self performSelector:@selector(getValuesTimeOut) withObject:nil afterDelay:3.0];
}

- (void) newVESCvalues:(NSNotification *)nObject {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(getValuesTimeOut) object:nil];
    
    NSData *myData = [nObject object];
    
    struct bldcMeasure newData;
    [myData getBytes:&newData length:sizeof(newData)];
    
    [lblAppStatus setText:@"VESC Communication OK"];
    [lblVescBattery setText:[NSString stringWithFormat:@"%0.1f volts", newData.inpVoltage]];
    
    [self updateGraph];
}

- (void) getValuesTimeOut {
    if (_UARTPeripheral == nil) {
        [lblAppStatus setText:@"VESC Communication timeout. Dropped connection."];
    } else {
        [lblAppStatus setText:@"VESC Communication timeout.  Retrying..."];
        [self performSelector:@selector(doGetValues) withObject:nil afterDelay:3.0];
    }
}

- (void) changeGraph:(UIGestureRecognizer *)gesture {
    if (gesture.state == UIGestureRecognizerStateBegan) {

        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Change Graph"
                                                                       message:@"Choose from VESC values:"
                                                                preferredStyle:UIAlertControllerStyleActionSheet];
        
        int i=0;
        for (NSString *title in measureNames) {
            UIAlertAction *aAction = [UIAlertAction actionWithTitle:title
                                                                  style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
                                                                      [[NSNotificationCenter defaultCenter] postNotificationName:@"changeGraphVariable" object:@(i)];
                                                                  }];
            
            [alert addAction:aAction];
            i++;
        }
        
        [self presentViewController:alert animated:YES completion:nil];
        
    }
}

- (void) changeGraphVariable:(NSNotification *)nObject {
    NSNumber *newGraphVariable = [nObject object];
    currentGraphVariable = [newGraphVariable intValue];
    [self updateGraph];
}

- (void) updateGraph {
    NSMutableArray *graphPoints = [[NSMutableArray alloc] initWithCapacity:_dataArray.count];
    
    struct bldcMeasure thisData;
    
    for (NSArray *data in _dataArray) {
//        NSDate *dateOfData = [data objectAtIndex:0];
        NSData *dataInData = [data objectAtIndex:1];
        
        [dataInData getBytes:&thisData length:sizeof(thisData)];
        
        switch (currentGraphVariable) {
            case 0:
                [graphPoints addObject:@(thisData.temp_mos1)];
                break;
            case 1:
                [graphPoints addObject:@(thisData.avgMotorCurrent)];
                break;
            case 2:
                [graphPoints addObject:@(thisData.avgInputCurrent)];
                break;
            case 3:
                [graphPoints addObject:@(thisData.dutyCycleNow)];
                break;
            case 4:
                [graphPoints addObject:@(thisData.rpm)];
                break;
            case 5:
                [graphPoints addObject:@(thisData.inpVoltage)];
                break;
            case 6:
                [graphPoints addObject:@(thisData.ampHours)];
                break;
            case 7:
                [graphPoints addObject:@(thisData.ampHoursCharged)];
                break;
            case 8:
                [graphPoints addObject:@(thisData.wattHours)];
                break;
            case 9:
                [graphPoints addObject:@(thisData.wattHoursCharged)];
                break;
            case 10:
                [graphPoints addObject:@(thisData.tachometer)];
                break;
            case 11:
                [graphPoints addObject:@(thisData.tachometerAbs)];
                break;
            case 112:
                [graphPoints addObject:@(thisData.fault_code)];
                break;
                
            default:
                break;
        }
    }
    
    aDataGraphView.dataPointsArray = graphPoints;
    aDataGraphView.dataPointsName = [measureNames objectAtIndex:currentGraphVariable];
    [aDataGraphView setNeedsDisplay];
}

#pragma mark - CBCentralManagerDelegate

// method called whenever you have successfully connected to the BLE peripheral
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    [lblAppStatus setText:@"Bluetooth: Peripheral connected"];
    
    _txCharacteristic = nil;
    _rxCharacteristic = nil;
    
    [peripheral setDelegate:self];
    [peripheral discoverServices:nil];
}

- (void) centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    [lblAppStatus setText:@"Bluetooth: Peripheral disconnected"];
    
    NSLog(@"Did disconnect peripheral %@", peripheral.name);
    _txCharacteristic = nil;
    _rxCharacteristic = nil;
    _UARTPeripheral = nil;
    [_aVescController resetPacket];
    
    // Start scanning for it again
    _centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
}

// CBCentralManagerDelegate - This is called with the CBPeripheral class as its main input parameter. This contains most of the information there is to know about a BLE peripheral.
- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI {
    NSString *localName = [advertisementData objectForKey:CBAdvertisementDataLocalNameKey];
    if ([localName length] > 0) {
        [lblAppStatus setText:@"Bluetooth: Peripheral discovered"];
        NSLog(@"Found the UART preipheral: %@", localName);
        _UARTPeripheral = peripheral;
        
        peripheral.delegate = self;
        [_centralManager connectPeripheral:peripheral options:@{CBConnectPeripheralOptionNotifyOnDisconnectionKey: [NSNumber numberWithBool:YES]}];

        [_centralManager stopScan];
    }
}

// method called whenever the device state changes.
- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    // Determine the state of the peripheral
    if ([central state] == CBCentralManagerStatePoweredOff) {
        [lblAppStatus setText:@"CoreBluetooth BLE hardware is powered off"];
    }
    else if ([central state] == CBCentralManagerStatePoweredOn) {
        [lblAppStatus setText:@"CoreBluetooth BLE hardware is powered on and ready"];
        
        NSArray *services = @[[CBUUID UUIDWithString:UART_SERVICE_UUID]];  //, [CBUUID UUIDWithString:DEVICE_INFO_UUID]];
        NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber  numberWithBool:YES], CBCentralManagerScanOptionAllowDuplicatesKey, nil];
        
        [_centralManager scanForPeripheralsWithServices:services options:options];
        [lblAppStatus setText:@"Scanning...."];
    }
    else if ([central state] == CBCentralManagerStateUnauthorized) {
        [lblAppStatus setText:@"CoreBluetooth BLE state is unauthorized"];
    }
    else if ([central state] == CBCentralManagerStateUnknown) {
        [lblAppStatus setText:@"CoreBluetooth BLE state is unknown"];
    }
    else if ([central state] == CBCentralManagerStateUnsupported) {
        [lblAppStatus setText:@"CoreBluetooth BLE hardware is unsupported on this platform"];
    }
}


#pragma mark - CBPeripheralDelegate

// CBPeripheralDelegate - Invoked when you discover the peripheral's available services.
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error {
    for (CBService *service in peripheral.services) {
        NSLog(@"Discovered service: %@", service.UUID);
        [lblAppStatus setText:@"Discovered UART Services"];
        [peripheral discoverCharacteristics:nil forService:service];
    }
}

// Invoked when you discover the characteristics of a specified service.
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error {
    if ([service.UUID isEqual:[CBUUID UUIDWithString:UART_SERVICE_UUID]])  {
        NSLog(@"Discovered UART service characteristics");
        [lblAppStatus setText:@"Discovered UART Characteristics"];
        
        for (CBCharacteristic *aChar in service.characteristics) {
            if ([aChar.UUID isEqual:[CBUUID UUIDWithString:TX_CHARACTERISTIC_UUID]]) {
                NSLog(@"Found TX service");
                _txCharacteristic = aChar;
                
                if (_rxCharacteristic != nil) [self UART_Ready];
                
            } else if ([aChar.UUID isEqual:[CBUUID UUIDWithString:RX_CHARACTERISTIC_UUID]]) {
                NSLog(@"Found RX service");
                _rxCharacteristic = aChar;
                [_UARTPeripheral setNotifyValue:YES forCharacteristic:_rxCharacteristic];
                
                if (_txCharacteristic != nil) [self UART_Ready];
            }
        }
        
        if (_txCharacteristic == nil && _rxCharacteristic == nil) {
            [lblAppStatus setText:@"RX and TX not discovered. Closing connection."];
            [_centralManager cancelPeripheralConnection:_UARTPeripheral];
        }
        
    } else if ([service.UUID isEqual:[CBUUID UUIDWithString:DEVICE_INFO_UUID]]) {
        NSLog(@"Discovered Device Info");
        
        for (CBCharacteristic *aChar in service.characteristics)
        {
            NSLog(@"Found device service: %@", aChar.UUID);
            [_UARTPeripheral readValueForCharacteristic:aChar];
        }
    }
}

// Invoked when you retrieve a specified characteristic's value, or when the peripheral device notifies your app that the characteristic's value has changed.
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    if (error) {
        NSLog(@"Error receiving notification for characteristic %@: %@", characteristic, error);
        return;
    }
    
    
    if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:TX_CHARACTERISTIC_UUID]]) { // 1
        // TX
        NSLog(@"TX update value");
        
    } else if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:RX_CHARACTERISTIC_UUID]]) {
        // RX
        NSLog(@"RX update value: %@", characteristic.value);
        
        if ([_aVescController process_incoming_bytes:characteristic.value] > 0) {
            struct bldcMeasure values = [_aVescController ProcessReadPacket];
            
            NSData *myData = [NSData dataWithBytes:&values length:sizeof(values)];
            
            // Add this VESC data, with Date as an array
            [_dataArray addObject:@[[NSDate date], myData]];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:@"newVESCvalues" object:myData];
            
            if (values.fault_code == FAULT_CODE_NO_DATA) {
                NSLog(@"Error");
            } else {
                NSLog(@"RPM: %ld", values.rpm);
            }
            if (isRecording) [self doGetValues];
        }
    } else {
        // Got some data, not sure what to do with it (probably the device service/information)
        NSString *inStr = @"";
        const uint8_t *bytes = characteristic.value.bytes;
        for (int i = 0; i < characteristic.value.length; i++) {
            inStr = [inStr stringByAppendingFormat:@"0x%02x, ", bytes[i]];
        }
        NSLog(@"inStr: %@", inStr);
    }
}

@end
