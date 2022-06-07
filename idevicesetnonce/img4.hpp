//
//  img4.hpp
//  idevicesetnonce
//
//  Created by MiniExploit on 5/31/22.
//

#ifndef img4_h
#define img4_h

#include "common.h"
#include <img4tool/img4tool.hpp>

std::pair<char*, char*> get_keys(const char *component_name, const char *product_type, const char *board, char *buildid);
std::pair<char*,char*> get_type_and_desc(char *buf, size_t len);
void decrypt(char *buf, size_t len, std::pair<char*, char*> keys, char **outbuf, size_t *outlen);
int pack_img4(char *buf, size_t len, char* blob, size_t blob_len, char **outbuf, size_t *outlen);
int pack_im4p(char *type, char *desc, char *buf, size_t len, char **outbuf, size_t *outlen);


#endif /* img4_h */
