#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>

#include <fcntl.h>
#include <net/if.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/ioctl.h>
#include <linux/if_tun.h>

#define PATH_NET_TUN "/dev/net/tun"


/* The device will only appear as a Linux netdevice after TUNSETIFF ioctl call
 *
 * Before multiqueue support was added to Linux tuntap driver, EBUSY would be
 * returned on TUNSETIFF when there was already another process opened the
 * /dev/net/tun device and TUNSETIFF with the same name
 *
 * After multiqueue support was added, EBUSY would be returned if
 * IFF_MULTI_QUEUE was not set and numqueues==1
 *
 * EBUSY can also happen when IFF_TUN_EXCL was present
 *
 * When IFF_MULTI_QUEUE is present in the first call to TUNSETIFF and becomes
 * part of tun->flags, the following TUNSETIFF will need to continue carry that
 * flag, other EINVAL will be returned
 */

int tap_open(char *ifname)
{
    struct ifreq ifr;
    int fd, ret;

    fd = open(PATH_NET_TUN, O_RDWR);
    if (fd < 0) {
        fprintf(stderr, "could not open %s: %m\n", PATH_NET_TUN);
        return -1;
    }
    memset(&ifr, 0, sizeof(ifr));
    ifr.ifr_flags = IFF_TAP | IFF_NO_PI;

    if (ifname[0] != '\0')
        strncpy(ifr.ifr_name, ifname, IFNAMSIZ-1);
    else
        strncpy(ifr.ifr_name, "tap%d", IFNAMSIZ-1);
    ret = ioctl(fd, TUNSETIFF, (void *) &ifr);
    if (ret != 0) {
        if (ifname[0] != '\0') {
            fprintf(stderr, "could not configure %s (%s): %m\n", PATH_NET_TUN, ifr.ifr_name);
        } else {
            fprintf(stderr, "could not configure %s: %m\n", PATH_NET_TUN);
        }
        close(fd);
        return -1;
    }
    return fd;
}

int main(int argc, char *argv[])
{
	char *ifname;
	int fd;

	if (argc > 1)
		ifname = argv[1];
	else {
		fprintf(stderr, "usage: %s <ifname>\n", argv[0]);
		return 1;
	}
	fd = tap_open(ifname);
	printf("pid: %d, fd:%d\n", getpid(), fd);
	getchar();
	return 0;
}
