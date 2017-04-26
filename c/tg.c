#include <linux/if_packet.h>
#include <linux/if_ether.h>

#include <arpa/inet.h>
#include <stdbool.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <sys/ioctl.h>
#include <sys/socket.h>
#include <net/if.h>
#include <getopt.h>
#include <unistd.h>
#include <time.h>

#ifdef DEBUG
#define debug(fmt, ...)	_log("debug: ", fmt, ##__VA_ARGS__)
#define debugfmt			"%s:%d: "
#define debugargs			__func__, __LINE__
#else
#define debug(fmt, ...)
#define debugfmt			"%s"
#define debugargs			""
#endif

#define __log(fmt, ...)	do {					\
	fprintf(stderr, fmt, ##__VA_ARGS__);			\
} while (0)
#define _log(level, fmt, ...)	do {	\
	__log(level debugfmt fmt, debugargs, ##__VA_ARGS__);	\
} while (0)

#define error(fmt, ...)		_log("error: ", fmt, ##__VA_ARGS__)
#define warn(fmt, ...)		_log("warn: ", fmt, ##__VA_ARGS__)
#define info(fmt, ...)		_log("info: ", fmt, ##__VA_ARGS__)

char *o_ifname;
char *o_fndata;
int o_count = 1;
int o_interval = 0;

static void usage(const char *progname)
{
	fprintf(stderr,
		"usage: %s -I <ifname> [-f <dataf>] [-i <ms>] [-c <count>]\n",
		progname);
}

static void parse_options(int argc, char *argv[])
{
	int opt;
	char *endptr;

	while ((opt = getopt(argc, argv, "I:c:f:w:i:h")) != -1) {
		switch (opt) {
		case 'I':
			o_ifname = optarg;
			break;
		case 'f':
			o_fndata = optarg;
			break;
		case 'c':
			o_count = strtoul(optarg, &endptr, 10);
			if (*endptr) {
				error("invalid count: %s\n", optarg);
				exit(EXIT_FAILURE);
			}
			break;
		case 'i':
			o_interval = strtoul(optarg, &endptr, 10);
			if (*endptr) {
				error("invalid interval: %s\n", optarg);
				exit(EXIT_FAILURE);
			}
			break;
		case 'h':
			usage(argv[0]);
			exit(EXIT_SUCCESS);
			break;
		default:
			break;
		}
	}

	if (!o_ifname) {
		error("no ifname\n");
		exit(EXIT_FAILURE);
	}
}

static int hex2bin(char *data, int datalen)
{
	int i, j;
	uint32_t nib, v;

	v = 0;
	for (i = 0, j = 0; i < datalen; i++) {
		if (data[i] >= '0' && data[i] <= '9')
			nib = data[i] - '0';
		else if (data[i] >= 'a' && data[i] <= 'f')
			nib = data[i] - 'a' + 10;
		else if (data[i] >= 'A' && data[i] <= 'F')
			nib = data[i] - 'A' + 10;
		else
			continue;
		v = (v << 4) | nib;
		if ((j & 1) == 1) {
			data[j >> 1] = v;
			v = 0;
		}
		j += 1;
	}
	return j >> 1;
}

int main(int argc, char *argv[])
{
	int sockfd;
	struct sockaddr_ll addrll;
	struct ifreq ifr;
	FILE *f;
	char *buf;
	int buflen, datalen;
	struct timespec ts;
	int i;
	int r, ret = -1;

	parse_options(argc, argv);

	sockfd = socket(AF_PACKET, SOCK_RAW, ETH_P_ALL);
	if (sockfd < 0) {
		perror("socket");
		return -1;
	}

	memset(&ifr, 0, sizeof(ifr));
	strncpy(ifr.ifr_name, o_ifname, IFNAMSIZ - 1);
	r = ioctl(sockfd, SIOCGIFINDEX, &ifr);
	if (r < 0) {
		perror("SIOCGIFINDEX");
		goto err_close;
	}

	if (o_fndata) {
		f = fopen(o_fndata, "rb");
		if (!f) {
			perror("fopen");
			goto err_close;
		}
	} else {
		f = stdin;
	}

	buflen = 1024;
	buf = malloc(buflen);
	if (!buf) {
		perror("malloc");
		goto err_fclose;
	}

	datalen = 0;
	while (!feof(f)) {
		int n, rem;

		rem = buflen - datalen;
		if (rem == 0) {
			char *b;

			b = realloc(buf, buflen + 1024);
			if (!b) {
				perror("realloc");
				goto err_free;
			}
			buf = b;
			buflen += 1024;
			rem += 1024;
		}
		n = fread(&buf[datalen], 1, rem, f);
		if (n <= 0)
			break;
		datalen += n;
		if (datalen > 1024 * 1024)
			break;
	}
	datalen = hex2bin(buf, datalen);

	memset(&addrll, 0, sizeof(addrll));
	addrll.sll_family = AF_PACKET;
	addrll.sll_protocol = ETH_P_ALL;
	addrll.sll_ifindex = ifr.ifr_ifindex;

	ts.tv_sec = o_interval / 1000;
	ts.tv_nsec = 1000000 * (o_interval % 1000);
	ret = 0;
	info("writing %d frames of %d bytes with interval %dms\n",
	     o_count, datalen, o_interval);
	for (i = 0; i < o_count;) {
		r = sendto(sockfd, buf, datalen, 0, (struct sockaddr *)&addrll,
			   sizeof(addrll));
		if (r < 0) {
			perror("sendto");
			goto err_free;
		}
		ret |= r < 0;
		i += 1;
		if (i < o_count)
			nanosleep(&ts, NULL);
	}

      err_free:
	free(buf);
      err_fclose:
	fclose(f);
      err_close:
	close(sockfd);
	return ret;
}
