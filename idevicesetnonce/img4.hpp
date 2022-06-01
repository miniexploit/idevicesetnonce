//
//  img4.hpp
//  idevicesetnonce
//
//  Created by macbookair on 5/31/22.
//

#ifndef img4_h
#define img4_h

#import <Foundation/Foundation.h>
#include <iostream>
#include <img4tool/img4tool.hpp>
#include "img4.h"


std::pair<char*, char*> get_keys(char *component_name, char *product_type, char *board, char *buildid);
void decrypt(char *buf, size_t len, std::pair<char*, char*> keys, char **outbuf, size_t *outlen);


#endif /* img4_h */
