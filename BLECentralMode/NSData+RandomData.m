//
//  NSData+RandomData.m
//  iOS-OpenCV-FaceRec
//
//  Created by qq on 8/8/2016.
//  Copyright © 2016 Fifteen Jugglers Software. All rights reserved.
//

#import "NSData+RandomData.h"

@implementation NSData (RandomData)

+ (NSData *)randomDataWithLength:(NSUInteger)length {
    
    uint8_t *bytes = malloc(sizeof(uint8_t) * length);
    SecRandomCopyBytes(kSecRandomDefault, length, bytes);
    return [NSData dataWithBytesNoCopy:bytes length:length freeWhenDone:YES];
}

@end
