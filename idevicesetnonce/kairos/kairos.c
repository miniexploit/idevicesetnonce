/*
 * main.c - main file for using kairos, used to patch unpacked IM4P iOS bootloader images
 *
 * Copyright 2020 dayt0n
 *
 * This file is part of kairos.
 *
 * kairos is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * kairos is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with kairos.  If not, see <https://www.gnu.org/licenses/>.
*/

#include "newpatch.h"
#include "kairos.h"

int kairos_patch(char *buffer, size_t len, char **outbuf, size_t *outlen) {
	
	char* bootArgs = NULL;
	char* command_str = NULL;
	uint64_t command_ptr = 0;
	struct iboot64_img iboot_in;
	int ret = 0;
	memset(&iboot_in, 0, sizeof(iboot_in));
	bool doNvramUnlock = true;

	
    iboot_in.len = len;
    iboot_in.buf = (uint8_t*)buffer;
    
	// patch
    if(has_magic(iboot_in.buf)) { // make sure we aren't dealing with a packed IMG4 container
            WARN("File does not appear to be stripped\n");
            return -1;
    }
	LOG("Base address: 0x%llx\n",get_iboot64_base_address(&iboot_in));
    bool pac = iboot64_pac_check(&iboot_in);
	if(has_kernel_load_k(&iboot_in)) {
		LOG("Does have kernel load\n");
		LOG("Enabling kernel debug...\n");
		ret = enable_kernel_debug(&iboot_in);
		if(ret < 0) // won't fail because it is not fatal, but it would really be nice if we had k-debug
			WARN("Could not enable kernel debug\n");
	}
	if(has_recovery_console_k(&iboot_in)) {
		if(command_str && (command_ptr != 0)) { // need to reassign command handler
			LOG("Changing command handler %s to 0x%llx...\n",command_str,command_ptr);
			ret = do_command_handler_patch(&iboot_in,command_str,command_ptr);
			if(ret < 0) // do not exit, just continue without cmdhandler patch
				WARN("Failed to patch command handler for %s\n",command_str);
		}
		if(doNvramUnlock) {
			LOG("Unlocking nvram...\n");
			ret = unlock_nvram(&iboot_in);
			if(ret < 0)
				WARN("Failed to unlock nvram\n");
		}
	}
    
	LOG("Patching out RSA signature check...\n");
	ret = rsa_sigcheck_patch(&iboot_in, pac);
	if(ret < 0)
		WARN("Error patching out RSA signature check\n");

    *outlen = iboot_in.len;
    *outbuf = (char *)iboot_in.buf;

	return 0;
}
