/*
 * Copyright (c) Yousong Zhou <yszhou4tech@gmail.com>
 *
 * sysctl net.ipv4.tcp_synack_retries
 *
 */
#include <netinet/in.h>
#include <stdarg.h>
#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>
#include <errno.h>
#include <string.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>

#include <arpa/inet.h>

void die(const char *fmt, ...)
{
	va_list ap;
	va_start(ap, fmt);
	vfprintf(stderr, fmt, ap);
	fprintf(stderr, ": %s\n", strerror(errno));
	va_end(ap);
	exit(1);
}

int main()
{
	int sockfd;
	int r;
	sockfd = socket(AF_INET, SOCK_STREAM, 0);
	if (sockfd < 0) {
		die("socket");
	}
	r = 1;
	setsockopt(sockfd, SOL_SOCKET, SO_REUSEADDR, &r, sizeof(r));

	struct sockaddr_storage addr;
	struct sockaddr_in *inaddr = (struct sockaddr_in *)&addr;
	inaddr->sin_family = AF_INET;
	inaddr->sin_port = htons(8000);
	r = inet_pton(AF_INET, "0.0.0.0", &inaddr->sin_addr);
	if (!r) {
		die("inet_pton");
	}

	r = bind(sockfd, (struct sockaddr *)&addr, sizeof(addr));
	if (r) {
		die("bind");
	}

	r = listen(sockfd, 0);
	if (r) {
		die("listen");
	}

	int cfd;
	socklen_t addrlen = sizeof(addr);
	cfd = accept(sockfd, (struct sockaddr *)&addr, &addrlen);
	if (cfd < 0) {
		die("accept");
	}
	fprintf(stderr, "accepted\n");
	while (1) {
		char b[1024];
		r = read(cfd, b, sizeof(b)-1);
		if (r < 0) {
			die("read");
		} else if (r == 0) {
			close(sockfd);
			close(cfd);
			die("closed");
		} else {
			b[r] = 0;
			fprintf(stderr, "%s", b);
		}
	}
	return 0;
}
