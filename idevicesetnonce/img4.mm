//
//  img4.m
//  idevicesetnonce
//
//  Created by MiniExploit on 5/31/22.
//

#include "img4.hpp"

std::pair<char*, char*> get_keys(const char *component_name, const char *product_type, const char *board, char *buildid) {
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


int pack_img4(char *buf, size_t len, char* blob, size_t blob_len, char **outbuf, size_t *outlen) {
    char *out = NULL;
    try {
        tihmstar::img4tool::ASN1DERElement im4p{buf, len};
        tihmstar::img4tool::ASN1DERElement im4m{blob, blob_len};
        tihmstar::img4tool::ASN1DERElement img4 = tihmstar::img4tool::getEmptyIMG4Container();
        img4 = tihmstar::img4tool::appendIM4PToIMG4(img4, im4p);
        img4 = tihmstar::img4tool::appendIM4MToIMG4(img4, im4m);
        
        out = (char*)malloc(img4.size());
        memcpy(out, img4.buf(), img4.size());
        
        *outbuf = out;
        *outlen = img4.size();
    } catch (...) {
        return -1;
    }
    return 0;
    
}

std::pair<char*,char*> get_type_and_desc(char *buf, size_t len) {
    tihmstar::img4tool::ASN1DERElement im4p(buf, len);
    return {(char*)im4p[1].getStringValue().c_str(), (char*)im4p[2].getStringValue().c_str()};
}

int pack_im4p(char *type, char *desc, char *buf, size_t len, char **outbuf, size_t *outlen) {
    tihmstar::img4tool::ASN1DERElement im4p = tihmstar::img4tool::getEmptyIM4PContainer(type, desc);
    im4p = tihmstar::img4tool::appendPayloadToIM4P(im4p, buf, len);
    *outbuf = (char*)im4p.buf();
    *outlen = im4p.size();
    return 0;
}
