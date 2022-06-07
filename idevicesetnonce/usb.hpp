//
//  usb.h
//  idevicesetnonce
//
//  Created by MiniExploit on 5/31/22.
//  Based on DFUDevice.h by rA9stuff: https://github.com/rA9stuff/LeetDown/blob/master/LeetDown_M/DFUDevice.h
//

#ifndef usb_h
#define usb_h

#include "common.h"
#include "libirecovery.h"

class usb {
private:
    irecv_client_t client = NULL;
    irecv_device_t device = NULL;
    const char *_productType;
    const char *_boardConfig;
    uint64_t _chipID;
    
    
public:
    usb(irecv_client_t &_client, irecv_device_t &_device): client(_client), device(_device) {
        open_connection();
    }
    
    int open_connection();
    int send_buffer(char *buffer, size_t len);
    int send_cmd(std::string cmd);
    void close_connection();
    int device_connected() {return (client != NULL);};
    
    char *get_product_type() {return (char *)_productType;};
    char *get_board_config() {return (char *)_boardConfig;};
    uint64_t get_chipid() {return _chipID;};
    char *get_mode();
    
    
};

#endif /* usb_h */
