
/*
 * smc_read.c: Written for Mac OS X 10.5. Compile as follows:
 *
 * gcc -Wall -o smc_read smc_read.c -framework IOKit
 */

#include <stdio.h>
#include <IOKit/IOKitLib.h>

typedef struct {
    uint32_t key;
    uint8_t  __d0[22];
    uint32_t datasize;
    uint8_t  __d1[10];
    uint8_t  cmd;
    uint32_t __d2;
    uint8_t  data[32];
} AppleSMCBuffer_t;

int
main(void)
{
    io_service_t service = IOServiceGetMatchingService(kIOMasterPortDefault,
                               IOServiceMatching("AppleSMC"));
    if (!service)
        return -1;

    io_connect_t port = (io_connect_t)0;
    kern_return_t kr = IOServiceOpen(service, mach_task_self(), 0, &port);
    IOObjectRelease(service);
    if (kr != kIOReturnSuccess)
        return kr;

    AppleSMCBuffer_t inputStruct = { 'OSK0', {0}, 32, {0}, 5, }, outputStruct;
    size_t outputStructCnt = sizeof(outputStruct);

    kr = IOConnectCallStructMethod((mach_port_t)port, (uint32_t)2,
             (const void*)&inputStruct, sizeof(inputStruct),
             (void*)&outputStruct, &outputStructCnt);
    if (kr != kIOReturnSuccess)
        return kr;

    int i = 0;
    for (i = 0; i < 32; i++)
        printf("%c", outputStruct.data[i]);

    inputStruct.key = 'OSK1';
    kr = IOConnectCallStructMethod((mach_port_t)port, (uint32_t)2,
             (const void*)&inputStruct, sizeof(inputStruct),
             (void*)&outputStruct, &outputStructCnt);
    if (kr == kIOReturnSuccess)
        for (i = 0; i < 32; i++)
            printf("%c", outputStruct.data[i]);

    printf("\n");

    return IOServiceClose(port);
}
