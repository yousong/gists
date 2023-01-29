#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include <string.h>
#include <errno.h>

#include <unistd.h>
#include <net/if.h>
#include <netinet/in.h>
#include <sys/ioctl.h>
#include <sys/socket.h>
#include <sys/types.h>

#include <linux/sockios.h>
#include <linux/types.h>
#include <linux/mii.h>

void errmsg(const char *fmtstr, ...)
{
	va_list argp;
	va_start(argp, fmtstr);
	vfprintf(stderr, fmtstr, argp);
	va_end(argp);
}

int main(int argc, char *argv[])
{
	int sockfd;
	struct mii_ioctl_data *mii = NULL;
	struct ifreq ifr;
	memset(&ifr, 0, sizeof(ifr));
	mii = (struct mii_ioctl_data *)&ifr.ifr_data;

	if (argc != 2 && argc != 4 && argc != 5) {
		errmsg("%s ethX\n", argv[0]);
		errmsg("%s ethX phyId addr\n", argv[0]);
		errmsg("%s ethX phyId addr value\n", argv[0]);
		return -1;
	}

	strncpy(ifr.ifr_name, argv[1], IFNAMSIZ - 1);
	sockfd = socket(PF_LOCAL, SOCK_DGRAM, 0);

	if (argc == 2) {
		if (ioctl(sockfd, SIOCGMIIPHY, &ifr) != 0) {
			if (ioctl(sockfd, SIOCGIFMTU, &ifr) == 0) {
				errmsg("ioctl %s SIOCGIFMTU: %d\n", ifr.ifr_name, ifr.ifr_mtu);
			}
			errmsg("ioctl %s SIOCGMIIPHY: %s\n", ifr.ifr_name, strerror(errno));
			return -2;
		} else {
			errmsg("get phy id %s: %d\n", ifr.ifr_name, mii->phy_id);
		}
	} else if (argc == 4) {
		mii->phy_id = (uint16_t)strtoul(argv[2], NULL, 0);
		mii->reg_num = (uint16_t)strtoul(argv[3], NULL, 0);

		if (ioctl(sockfd, SIOCGMIIREG, &ifr) == 0) {
			errmsg("read phy %d, reg 0x%x: 0x%x\n", mii->phy_id, mii->reg_num, mii->val_out);
			printf("0x%x", mii->val_out);
		} else {
			errmsg("read phy %d, reg 0x%x: %s\n", mii->phy_id, mii->reg_num, strerror(errno));
		}

	} else if (argc == 5) {
		mii->phy_id = (uint16_t)strtoul(argv[2], NULL, 0);
		mii->reg_num = (uint16_t)strtoul(argv[3], NULL, 0);
		mii->val_in = (uint16_t)strtoul(argv[4], NULL, 0);

		if (ioctl(sockfd, SIOCSMIIREG, &ifr) == 0) {
			errmsg("write phy %d, reg 0x%x: 0x%x\n", mii->phy_id, mii->reg_num, mii->val_in);
		} else {
			errmsg("write phy %d, reg 0x%x: %s\n", mii->phy_id, mii->reg_num, strerror(errno));
		}
	} else {
		errmsg("mdio ethX phyId addr value\n");
	}

	close(sockfd);

	return 0;
}
