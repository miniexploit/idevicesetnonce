//
//  ipsw.hpp
//  idevicesetnonce
//
//  Created by macbookair on 6/1/22.
//

#ifndef ipsw_h
#define ipsw_h

#import <Foundation/Foundation.h>
#include <iostream>
#include <libfragmentzip/libfragmentzip.h>

char *get_ipsw_info(char *product_type, char *version, char *requested_data);
char *get_component_path(const char *component, const char *board);

int dl_to_file(char *url, char *path, char *output);
int dl_to_memory(char *url, char *path, char **outbuf, size_t *outlen);

#endif /* ipsw_h */
