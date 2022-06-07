//
//  kairos.h
//  idevicesetnonce
//
//  Created by macbookair on 5/31/22.
//

#ifndef kairos_h
#define kairos_h


#ifdef __cplusplus
extern "C" {
#endif
int kairos_patch(char *buffer, size_t len, char **outbuf, size_t *outlen);
#ifdef __cplusplus
}
#endif


#endif /* kairos_h */
