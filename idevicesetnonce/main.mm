//
//  main.m
//  idevicesetnonce
//
//  Created by MiniExploit on 5/31/22.
//

#include <iostream>
#include "usb.hpp"
#include "img4.hpp"
#include "ipsw.hpp"
#include "kairos/kairos.h"

usb *usbdev;

irecv_client_t client = NULL;
irecv_device_t device = NULL;


char *get_generator_from_shsh(char *path) {
    NSDictionary *dict=[[NSDictionary alloc] initWithContentsOfFile:[NSString stringWithFormat:@"%s", path]];
    return (char*)[dict[@"generator"] cStringUsingEncoding:NSASCIIStringEncoding];
}
char *get_ap_img4_ticket_from_shsh(char *path) {
    NSDictionary *dict=[[NSDictionary alloc] initWithContentsOfFile:[NSString stringWithFormat:@"%s", path]];
    return (char*)[dict[@"ApImg4Ticket"] cStringUsingEncoding:NSASCIIStringEncoding];
}

int main(int argc, const char * argv[]) {
    printf("idevicesetnonce - An utility for setting nonce on checkm8-vulnerable devices\n");
    
    int res;
    char *version = NULL;
    char *generator = NULL;
    char *blob_path = NULL;
    
    if(argc < 3) {
        printf("usage: idevicesetnonce <iOS version> <SHSH blob>\n");
        printf("    <iOS version>\t\tThe iOS version about to restored to\n");
        printf("    <SHSH blob>\t\tSHSH blob used for restoring\n");
        printf("Version: 0.1\n");
        printf("Source code: https://github.com/Mini-Exploit/idevicesetnonce\n");
        printf("Report issue: https://github.com/Mini-Exploit/idevicesetnonce/issue\n");
        return 1;
    }
    version = (char*)argv[1];
    blob_path = (char*)argv[2];
    printf("Waiting for DFU device..\n");
    usbdev = new usb(client, device);
    if(!(usbdev -> device_connected())) {
        while(usbdev -> open_connection() != 0) {}
    }
    char *mode;
    printf("Found %s with boardconfig %s in %s mode\n", usbdev -> get_product_type(), usbdev -> get_board_config(), mode = usbdev -> get_mode());
    
    if(strcmp(mode, "DFU") != 0) {
        fprintf(stderr, "ERROR: Device is not in DFU mode\n");
        return -1;
    }
    char *blob = NULL;
    blob = get_ap_img4_ticket_from_shsh(blob_path);
    
    generator = get_generator_from_shsh(blob_path);
    if(!generator) {
        fprintf(stderr, "ERROR: Failed to get generator from SHSH\n");
    }
    
    char *buildid = get_ipsw_info(usbdev -> get_product_type(), version, "buildid");
    /* Instead of trying to get the url with the iOS version, we get it with the BuildID because it's unique while some iOS versions have multiple BuildID */
    char *url = get_ipsw_info(usbdev -> get_product_type(), buildid, "url");

    char *ibss = NULL;
    size_t ibss_len;

    res = dl_to_file(url, "BuildManifest.plist", ".BuildManifest.plist");
    if(res != 0) {
        fprintf(stderr, "ERROR: Failed to download BuildManifest.plist\n");
        return -1;
    }
    char *ibss_remote_path = get_component_path("iBSS", usbdev -> get_board_config());
    if(!ibss_remote_path) {
        fprintf(stderr, "ERROR: Failed to get %s component path", "iBSS");
        return -1;
    }
    printf("Downloading iBSS\n");
    res = dl_to_memory(url, ibss_remote_path, &ibss, &ibss_len);
    if(res != 0) {
        fprintf(stderr, "ERROR: Failed to download iBSS\n");
        return -1;
    }
    printf("Patching iBSS\n");
    std::pair <char*,char*> iBSSKeys = get_keys("iBSS", usbdev -> get_product_type(), usbdev -> get_board_config(), buildid);
    decrypt(ibss, ibss_len, iBSSKeys, &ibss, &ibss_len);
    kairos_patch(ibss, ibss_len, &ibss, &ibss_len);
    res = img4_stitch_component("iBSS", ibss, ibss_len, blob, sizeof(blob), &ibss, &ibss_len);
    if(res != 0) return -1;
    printf("Sending iBSS\n");
    if(usbdev -> send_buffer(ibss, ibss_len) != 0) {
        fprintf(stderr, "ERROR: Failed to send iBSS\n");
        return -1;
    }
    
    sleep(2);
    
    
    if(usbdev -> get_chipid() < 0x8010) {
        char *ibec = NULL;
        size_t ibec_len;
        char *ibec_remote_path = get_component_path("iBEC", usbdev -> get_board_config());
        if(!ibec_remote_path) {
            fprintf(stderr, "ERROR: Failed to get %s component path", "iBEC");
            return -1;
        }
        printf("Downloading iBEC\n");
        res = dl_to_memory(url, ibec_remote_path, &ibec, &ibec_len);
        if(res != 0) {
            fprintf(stderr, "ERROR: Failed to download iBEC\n");
            return -1;
        }
        printf("Patching iBEC\n");
        std::pair<char*,char*> iBECKeys = get_keys("iBEC", usbdev -> get_product_type(), usbdev -> get_board_config(), buildid);
        decrypt(ibec, ibec_len, iBECKeys, &ibec, &ibec_len);
        kairos_patch(ibec, ibec_len, &ibec, &ibec_len);
        res = img4_stitch_component("iBEC", ibec, ibec_len, blob, sizeof(blob), &ibec, &ibec_len);
        if(res != 0) return -1;
        printf("Sending iBEC\n");
        if(usbdev -> send_buffer(ibec, ibec_len) != 0) {
            fprintf(stderr, "ERROR: Failed to send iBEC\n");
            return -1;
        }
        sleep(2);
        if(!(usbdev -> device_connected()))
            if(usbdev -> open_connection() != 0) {
                fprintf(stderr, "Failed to reconnect to device\n");
                return -1;
            }
    }
    printf("Setting nonce generator: %s\n", generator);
    res = usbdev -> send_cmd("setenv com.apple.System.boot-nonce %s", generator);
    if(res != 0) {
        fprintf(stderr, "ERROR: Failed to set nonce generator\n");
        return -1;
    }
    res = usbdev -> send_cmd("saveenv");
    if(res != 0) {
        fprintf(stderr, "ERROR: Failed to save nvram\n");
        return -1;
    }
    printf("Rebooting device\n");
    usbdev -> send_cmd("reboot");
    printf("Done!\n");
    [[NSFileManager defaultManager] removeItemAtPath:@".BuildManifest.plist" error:NULL];
    return 0;

}


