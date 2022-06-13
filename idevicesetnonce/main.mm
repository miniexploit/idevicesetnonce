//
//  main.m
//  idevicesetnonce
//
//  Created by MiniExploit on 5/31/22.
//

#include "common.h"
#include "usb.hpp"
#include "img4.hpp"
#include "ipsw.hpp"
#include "kairos/kairos.h"

usb *usbdev;

irecv_client_t client = NULL;
irecv_device_t device = NULL;

int idevicesetnonce_debug = 0;

char *get_generator_from_shsh(const char *path) {
    NSDictionary *dict=[[NSDictionary alloc] initWithContentsOfFile:[NSString stringWithFormat:@"%s", path]];
    return (char*)[dict[@"generator"] cStringUsingEncoding:NSASCIIStringEncoding];
}

std::pair<char*, size_t> get_ap_img4_ticket_from_shsh(const char *path) {
    NSDictionary *dict=[[NSDictionary alloc] initWithContentsOfFile:[NSString stringWithFormat:@"%s", path]];
    NSData *ApImg4Ticket = dict[@"ApImg4Ticket"];
    return {(char*)[ApImg4Ticket bytes], (size_t)[ApImg4Ticket length]};
}
 
int parse_argument(int argc, const char * argv[], const char **firstArg, const char **secondArg) {
    if(argc < 3) {
        printf("usage: idevicesetnonce <iOS version> <SHSH blob> [-d]\n");
        printf("    <iOS version>\t\t\tTarget iOS version to downgrade to\n");
        printf("    <SHSH blob>\t\t\tSHSH blob used for restoring\n");
        printf("    -d\t\t\tPrint more information during process\n");
        printf("Source code: https://github.com/Mini-Exploit/idevicesetnonce\n");
        printf("Report issue: https://github.com/Mini-Exploit/idevicesetnonce/issue\n");
        return 1;
    }
    for(int i = 0; i < argc; i++) {
        if(!strcmp(argv[i], "-d")) {
            idevicesetnonce_debug = 1;
            for(int tmp = 0; tmp < argc; tmp++) printf("argv[%d]=%s\n",tmp,argv[tmp]);
            for(int j = i; j < argc; ++j) argv[j] = argv[j+1];
            break;
        }
    }
    *firstArg = argv[1];
    *secondArg = argv[2];
    return 0;
}

int main(int argc, const char * argv[]) {
    printf("idevicesetnonce - An utility for setting nonce on checkm8-vulnerable devices\n");
    printf("Statically compiled: ");
#ifdef IS_STATICALLY_COMPILED
    printf("yes\n");
#else
    printf("no\n");
#endif
    int res;
    const char *version = NULL;
    const char *generator = NULL;
    const char *blob_path = NULL;
    
    if(parse_argument(argc, argv, &version, &blob_path)) return 1;
    
    printf("Waiting for DFU device...\n");
    usbdev = new usb(client, device);
    if(!(usbdev -> device_connected())) {
        while(usbdev -> open_connection() != 0) {}
    }
    char *mode;
    const char *product_type = usbdev -> get_product_type();
    const char *hardware_model = usbdev -> get_board_config();
    printf("Found %s with boardconfig %s in %s mode\n", product_type, hardware_model, mode = usbdev -> get_mode());
    
    if(strcmp(mode, "DFU") != 0) {
        error("ERROR: Device is not in DFU mode\n");
        return -1;
    }
    
    std::pair<char*, size_t> blob;
    generator = get_generator_from_shsh(blob_path);
    if(!generator) {
        error("ERROR: Failed to get generator from SHSH\n");
        return -1;
    }
    debug("Got generator from SHSH: %s", generator);
    
    char *buildid = get_ipsw_info(product_type, version, "buildid");
    if(!buildid) {
        error("ERROR: Failed to get BuildID for iOS %s", version);
        return -1;
    }
    debug("BuildID: %s",buildid);
    /* Instead of trying to get the url with the iOS version, we get it with the BuildID because it's unique while some iOS versions have multiple BuildIDs */
    char *url = get_ipsw_info(product_type, buildid, "url");
    if(!url) {
        error("ERROR: Failed to get iPSW URL for iOS %s", version);
        return -1;
    }
    debug("iPSW URL: %s", url);

    char *ibss = NULL;
    size_t ibss_len;
    
    char *org_ibss = NULL;
    size_t org_ibss_len;

    res = dl_to_file(url, "BuildManifest.plist", ".BuildManifest.plist");
    if(res != 0) {
        error("ERROR: Failed to download BuildManifest.plist\n");
        return -1;
    }
    char *ibss_remote_path = get_component_path("iBSS", hardware_model);
    if(!ibss_remote_path) {
        error("ERROR: Failed to get %s component path", "iBSS");
        return -1;
    }
    debug("iBSS path: %s", ibss_remote_path);
    printf("Downloading iBSS\n");
    res = dl_to_memory(url, ibss_remote_path, &ibss, &ibss_len);
    if(res != 0) {
        error("ERROR: Failed to download iBSS\n");
        return -1;
    }
    org_ibss = ibss;
    org_ibss_len = ibss_len;
    printf("Patching iBSS\n");
    std::pair <char*,char*> iBSSKeys = get_keys("iBSS", product_type, hardware_model, buildid);
    decrypt(ibss, ibss_len, iBSSKeys, &ibss, &ibss_len);
    kairos_patch(ibss, ibss_len, &ibss, &ibss_len);
    printf("Repacking iBSS\n");
    std::pair<char*,char*> iBSSTypeAndDesc = get_type_and_desc(org_ibss, org_ibss_len);
    res = pack_im4p(iBSSTypeAndDesc.first, iBSSTypeAndDesc.second, ibss, ibss_len, &ibss, &ibss_len);
    if(res != 0) {
        error("ERROR: Failed to pack iBSS\n");
        return -1;
    }
    blob = get_ap_img4_ticket_from_shsh(blob_path);
    res = pack_img4(ibss, ibss_len, blob.first, blob.second, &ibss, &ibss_len);
    if(res != 0) {
        error("ERROR: Failed to pack iBSS\n");
        return -1;
    }
    printf("Sending iBSS\n");
    if(usbdev -> send_buffer(ibss, ibss_len) != 0) {
        error("ERROR: Failed to send iBSS\n");
        return -1;
    }
    sleep(2);
    if(usbdev -> get_chipid() < 0x8010) {
        char *ibec = NULL;
        size_t ibec_len;
        char *org_ibec = NULL;
        size_t org_ibec_len;
        char *ibec_remote_path = get_component_path("iBEC", hardware_model);
        if(!ibec_remote_path) {
            error("ERROR: Failed to get %s component path", "iBEC");
            return -1;
        }
        debug("iBEC path: %s", ibec_remote_path);
        printf("Downloading iBEC\n");
        res = dl_to_memory(url, ibec_remote_path, &ibec, &ibec_len);
        if(res != 0) {
            error("ERROR: Failed to download iBEC\n");
            return -1;
        }
        org_ibec = ibec;
        org_ibec_len = ibec_len;
        printf("Patching iBEC\n");
        std::pair<char*,char*> iBECKeys = get_keys("iBEC", product_type, hardware_model, buildid);
        decrypt(ibec, ibec_len, iBECKeys, &ibec, &ibec_len);
        kairos_patch(ibec, ibec_len, &ibec, &ibec_len);
        printf("Repacking iBEC\n");
        std::pair<char*,char*> iBECTypeAndDesc = get_type_and_desc(org_ibec, org_ibec_len);
        res = pack_im4p(iBECTypeAndDesc.first, iBECTypeAndDesc.second, ibec, ibec_len, &ibec, &ibec_len);
        if(res != 0) {
            error("ERROR: Failed to pack iBEC\n");
            return -1;
        }
        blob = get_ap_img4_ticket_from_shsh(blob_path);
        res = pack_img4(ibec, ibec_len, blob.first, blob.second, &ibec, &ibec_len);
        if(res != 0) {
            error("ERROR: Failed to pack iBEC\n");
            return -1;
        }
        printf("Sending iBEC\n");
        if(usbdev -> send_buffer(ibec, ibec_len) != 0) {
            error("ERROR: Failed to send iBEC\n");
            return -1;
        }
        sleep(2);
    }

    if(usbdev -> open_connection() != 0) {
        error("ERROR: Failed to reconnect to device\n");
        return -1;
    }
    
    mode = usbdev -> get_mode();
    debug(mode);
    if(strcmp(mode, "Recovery") != 0) {
        error("ERROR: Device did not reconnect in Recovery mode after sending iBSS/iBEC\n");
        return -1;
    }
    printf("Setting nonce generator: %s\n", generator);
    res = usbdev -> send_cmd(std::string("setenv com.apple.System.boot-nonce ").append(generator));
    if(res != 0) {
        error("ERROR: Failed to set nonce generator\n");
        return -1;
    }
    res = usbdev -> send_cmd("saveenv");
    if(res != 0) {
        error("ERROR: Failed to save nvram\n");
        return -1;
    }
    printf("Rebooting device\n");
    usbdev -> send_cmd("setenv auto-boot false");
    usbdev -> send_cmd("saveenv");
    usbdev -> send_cmd("reset");
    error("Done!\n");
    return 0;
   
}


