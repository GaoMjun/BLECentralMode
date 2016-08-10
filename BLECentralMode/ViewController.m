//
//  ViewController.m
//  BLECentralMode
//
//  Created by qq on 10/8/2016.
//  Copyright © 2016 GitHub. All rights reserved.
//

#import "ViewController.h"
#import <CoreBluetooth/CoreBluetooth.h>
#import "NSString+HexString.h"
#import "NSData+RandomData.h"

// uuidgen
#define kServiceUUID @"6BC6543C-2398-4E4A-AF28-E4E0BF58D6BC"
#define kCharacteristicWriteUUID @"9D69C18C-186C-45EA-A7DA-6ED7500E9C97"
#define kCharacteristicReadUUID @"F973A2FB-36E0-4CA1-A053-8311F0C23CA2"

@interface ViewController ()
<CBCentralManagerDelegate,
CBPeripheralDelegate>

@property (nonatomic, strong) CBCentralManager *mgr;
@property (nonatomic, strong) CBPeripheral *peripheral;
@property (nonatomic, strong) CBService *service;
@property (nonatomic, strong) CBCharacteristic *characteristicRead;
@property (nonatomic, strong) CBCharacteristic *characteristicWrite;

@property (nonatomic, strong) NSTimer *sendTimer;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _mgr = [[CBCentralManager alloc] init];
    _mgr.delegate = self;
}

#pragma mark - CBCentralManagerDelegate

- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    
    if (central.state == CBCentralManagerStatePoweredOn) {
        [self.mgr scanForPeripheralsWithServices:nil options:nil];
        
    } else {
        NSLog(@"%s state:%ld", __func__, (long)central.state);
    }
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI {
    
    NSLog(@"%@", peripheral.name);
    
    if ([peripheral.name isEqualToString:@"👀"]) {
        NSLog(@"%@", RSSI);
        
        if (RSSI.intValue > -70) {
            peripheral.delegate = self;
            self.peripheral = peripheral;
            
            [self.mgr connectPeripheral:peripheral options:nil];
            
        } else {
            NSLog(@"weak signal");
        }
    }
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    
    if ([peripheral.name isEqualToString:@"👀"]) {
        
        [self.mgr stopScan];
        
        [peripheral discoverServices:@[[CBUUID UUIDWithString:kServiceUUID]]];
    }
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    NSLog(@"%s error:%@", __func__, error);
}

#pragma mark - CBPeripheralDelegate

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error {
    
    if (!error) {
        
        for (CBService *service in peripheral.services) {
            
            if ([service.UUID isEqual:[CBUUID UUIDWithString:kServiceUUID]]) {
                self.service = service;
                
                [peripheral discoverCharacteristics:@[[CBUUID UUIDWithString:kCharacteristicReadUUID],
                                                      [CBUUID UUIDWithString:kCharacteristicWriteUUID]]
                                         forService:service];
                
                break;
            }
        }
        
    } else {
        
        NSLog(@"%s error:%@", __func__, error);
    }
    
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error {
    if (!error) {
        
        for (CBCharacteristic *characteristic in service.characteristics) {
            
            if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:kCharacteristicReadUUID]]) {
                self.characteristicRead = characteristic;
                
                [self characteristicSupportMode:characteristic];
                
                [peripheral setNotifyValue:YES forCharacteristic:characteristic];
                
//                self.sendTimer = [NSTimer scheduledTimerWithTimeInterval:.03 target:self selector:@selector(sendData) userInfo:nil repeats:YES];
                
            } else if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:kCharacteristicWriteUUID]]) {
                self.characteristicWrite = characteristic;
                
                [self characteristicSupportMode:characteristic];
                
                [self sendData];
            }
        }
        
    } else {
        
        NSLog(@"%s error:%@", __func__, error);
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    
    if (!error) {
        
        if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:kCharacteristicReadUUID]]) {

            
        } else if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:kCharacteristicWriteUUID]]) {

        }
        
    } else {
        
        NSLog(@"%s error:%@", __func__, error);
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    
    if (!error) {
        
        if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:kCharacteristicReadUUID]]) {
            NSLog(@"%@", characteristic.value);
            
            [self sendData];
            
        } else if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:kCharacteristicWriteUUID]]) {
            NSLog(@"%@", characteristic.value);
        }
        
    } else {
        
        NSLog(@"%s error:%@", __func__, error);
    }
}

- (void)sendData {
    NSData *data = [NSData randomDataWithLength:20];
    
    [self.peripheral writeValue:data forCharacteristic:self.characteristicWrite type:CBCharacteristicWriteWithoutResponse];
}

- (void)characteristicSupportMode:(CBCharacteristic *)characteristic {
    if (characteristic.properties & CBCharacteristicPropertyBroadcast) {
        NSLog(@"characteristic: %@ support CBCharacteristicPropertyBroadcast", characteristic.UUID);
    }
    if (characteristic.properties & CBCharacteristicPropertyRead) {
        NSLog(@"characteristic: %@ support CBCharacteristicPropertyRead", characteristic.UUID);
    }
    if (characteristic.properties & CBCharacteristicPropertyWriteWithoutResponse) {
        NSLog(@"characteristic: %@ support CBCharacteristicPropertyWriteWithoutResponse", characteristic.UUID);
    }
    if (characteristic.properties & CBCharacteristicPropertyWrite) {
        NSLog(@"characteristic: %@ support CBCharacteristicPropertyWrite", characteristic.UUID);
    }
    if (characteristic.properties & CBCharacteristicPropertyNotify) {
        NSLog(@"characteristic: %@ support CBCharacteristicPropertyNotify", characteristic.UUID);
        
        [self.peripheral setNotifyValue:YES forCharacteristic:characteristic];
    }
    if (characteristic.properties & CBCharacteristicPropertyIndicate) {
        NSLog(@"characteristic: %@ support CBCharacteristicPropertyIndicate", characteristic.UUID);
    }
    if (characteristic.properties & CBCharacteristicPropertyAuthenticatedSignedWrites) {
        NSLog(@"characteristic: %@ support CBCharacteristicPropertyAuthenticatedSignedWrites", characteristic.UUID);
    }
    if (characteristic.properties & CBCharacteristicPropertyExtendedProperties) {
        NSLog(@"characteristic: %@ support CBCharacteristicPropertyExtendedProperties", characteristic.UUID);
    }
    if (characteristic.properties & CBCharacteristicPropertyNotifyEncryptionRequired) {
        NSLog(@"characteristic: %@ support CBCharacteristicPropertyNotifyEncryptionRequired", characteristic.UUID);
    }
    if (characteristic.properties & CBCharacteristicPropertyIndicateEncryptionRequired) {
        NSLog(@"characteristic: %@ support CBCharacteristicPropertyIndicateEncryptionRequired", characteristic.UUID);
    }
}

@end
