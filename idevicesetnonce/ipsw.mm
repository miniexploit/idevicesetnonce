//
//  ipsw.mm
//  idevicesetnonce
//
//  Created by MiniExpoit on 6/1/22.
//

#include "ipsw.hpp"

char *get_ipsw_info(const char *product_type, const char *version, const char *requested_data) {
    std::string std_ipsw_api = "https://api.ipsw.me/v2.1/";
    std_ipsw_api.append(product_type);
    std_ipsw_api.append("/");
    std_ipsw_api.append(version);
    std_ipsw_api.append("/");
    std_ipsw_api.append(requested_data);
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%s", std_ipsw_api.c_str()]];
    NSData *data = [NSData dataWithContentsOfURL:url];
    return (char*)[data bytes];
}

int dl_to_memory(char *url, char *path, char **outbuf, size_t *outlen) {
    fragmentzip_t *ipsw = fragmentzip_open(url);
    if(!ipsw) return -1;
    if(fragmentzip_download_to_memory(ipsw, path, outbuf, outlen, NULL) != 0) {
        fragmentzip_close(ipsw);
        return -1;
    }
    fragmentzip_close(ipsw);
    return 0;
}

int dl_to_file(char *url, char *path, char *output) {
    fragmentzip_t *ipsw = fragmentzip_open(url);
    if(!ipsw) return -1;
    if(fragmentzip_download_file(ipsw, path, output, NULL) != 0) {
        fragmentzip_close(ipsw);
        return -1;
    }
    fragmentzip_close(ipsw);
    return 0;
}

char *get_component_path(const char *component, const char *board) {
    NSDictionary *dict=[[NSDictionary alloc] initWithContentsOfFile:@".BuildManifest.plist"];
    NSString *hwmdl = [NSString stringWithFormat:@"%s", board];
    for(int i = 0; i < [dict[@"BuildIdentities"] count]; i++) {
        id devclass = [dict[@"BuildIdentities"] objectAtIndex:i];
        if(devclass[@"Info"][@"DeviceClass"] == hwmdl) {
            return (char*)[devclass[@"Manifest"][[NSString stringWithFormat:@"%s", component]][@"Info"][@"Path"] cStringUsingEncoding:NSASCIIStringEncoding];
        }
    }
    return NULL;
}
