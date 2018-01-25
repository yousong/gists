#include <pthread.h>
#include <sys/stat.h>
#include <sys/time.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <stdbool.h>

pthread_cond_t cond;
pthread_mutex_t mutx;

/*
 * pthread_create()
 * pthread_join()
 * pthread_mutex_lock()
 * pthread_cond_wait()
 * pthread_cond_signal()
 */

void *writefn(void *d)
{
	const char *fn = d;
	FILE *fp;
	int v;
	int i = 0;

	v = random();
	fp = fopen(fn, "w");
	if (!fp) {
		perror("open");
		pthread_cond_signal(&cond);
		return 0;
	}
	pthread_cond_signal(&cond);
	while (true) {
		fprintf(fp, "%d\n", v);
		v += random() & 3;

		i++;
		if ((i & 0xfff) == 0) {
			struct stat st;
			if (!stat(fn, &st)) {
				if (st.st_size >= 1024 * 1024) {
					break;
				}
			} else {
				perror("stat");
			}
		}
	}
	fclose(fp);
	return 0;
}

int main()
{
	int i;
	char fn[16];
	pthread_t t[8];
	struct timeval tv;

	gettimeofday(&tv, NULL);
	srandom(tv.tv_usec);
	pthread_mutex_lock(&mutx);
	for (i = 0; i < 8; i++) {
		sprintf(fn, "fn%02d", i);
		pthread_create(&t[i], NULL, writefn, fn);
		pthread_cond_wait(&cond, &mutx);
	}
	for (i = 0; i < 8; i++) {
		pthread_join(t[i], NULL);
	}
	return 0;
}
