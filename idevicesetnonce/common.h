//
//  common.h
//  idevicesetnonce
//
//  Created by MiniExploit on 6/2/22.
//
//

#ifndef common_h
#define common_h

#import <Foundation/Foundation.h>
#include <iostream>

extern int idevicesetnonce_debug;

#define error(msg ...) {\
    [[NSFileManager defaultManager] removeItemAtPath:@".BuildManifest.plist" error:NULL];\
    fprintf(stderr, msg);\
    fflush(stderr);\
}

#define debug(msg ...) {\
    if(idevicesetnonce_debug) {\
        printf("DEBUG: ");\
        printf(msg);\
        printf("\n");\
    }\
}

#endif /* common_h */
