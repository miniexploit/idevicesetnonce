//
//  img4.m
//  idevicesetnonce
//
//  Created by macbookair on 5/31/22.
//

#include "img4.hpp"

std::pair<char*, char*> get_keys(char *component_name, char *product_type, char *board, char *buildid) {
    const char *iv = NULL;
    const char *key = NULL;
    std::string m1sta_api = "https://api.m1sta.xyz/wikiproxy/";
    m1sta_api.append(product_type);
    m1sta_api.append("/");
    m1sta_api.append(board);
    m1sta_api.append("/");
    m1sta_api.append(buildid);
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%s", m1sta_api.c_str()]];
    NSData *data = [NSData dataWithContentsOfURL:url];
    NSDictionary* json = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
    NSArray* keys = [json objectForKey:@"keys"];
    for(int i = 0; i < [keys count]; i++) {
        id imgstruct = [keys objectAtIndex:i];
        if([[imgstruct valueForKey:@"image"] isEqual:[NSString stringWithFormat:@"%s", component_name]]) {
            iv = [[imgstruct valueForKey:@"iv"] cStringUsingEncoding:NSASCIIStringEncoding];
            key = [[imgstruct valueForKey:@"key"] cStringUsingEncoding:NSASCIIStringEncoding];
        }
    }

    return {(char*)iv, (char*)key};
}


void decrypt(char *buf, size_t len, std::pair<char*, char*> keys, char **outbuf, size_t *outlen) {

    tihmstar::img4tool::ASN1DERElement im4p(buf, len);
    tihmstar::img4tool::ASN1DERElement payload = getPayloadFromIM4P(im4p, keys.first, keys.second, NULL, NULL, 0);
    *outbuf = (char*)payload.payload();
    *outlen = payload.payloadSize();

}


/*
void dectest() {
    FILE *ibss = NULL;
    const char *ibss_data;
    size_t ibss_len;
    std::pair<char*, char*> keys = get_keys("iBSS", "iPhone9,1", "d10ap", "18C66");
    ibss = fopen("/Users/macbookair/Desktop/ra1nstorm/iBSS.im4p", "r");
    fseek(ibss, 0, SEEK_END);
    ibss_len = ftell(ibss);
    fseek(ibss, 0, SEEK_SET);
    ibss_data = (char*)malloc(ibss_len);
    fclose(ibss);
    const char *decibss;
    size_t decibss_len;
    decrypt(ibss_data, ibss_len, keys, &decibss, &decibss_len);
    ibss = fopen("/Users/macbookair/Desktop/ra1nstorm/iBSS.im4p", "wb");
    fwrite(ibss_data, ibss_len, 1, ibss);
    fclose(ibss);
}
*/
