//
//  rotten-Bridging-Header.m
//  rotten
//
//  Created by Ziyang Tan on 9/23/14.
//  Copyright (c) 2014 ziyang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "rotten-Bridging-Header.h"

@implementation AFImageResponseSerializer (CustomInit)
+ (instancetype)sharedSerializer {
    return [AFImageResponseSerializer serializer];
}
@end

