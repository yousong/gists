BINS:=tg pthreads_do mdio

all: $(BINS)

# -static requires glibc-static on rhel
tg: tg.c
	$(CC) -o $@ -static -Wall $(CFLAGS) $(CPPFLAGS) $^

pthreads_do: pthreads_do.c
	$(CC) -o $@ -Wall -lpthread $(CFLAGS) $(CPPFLAGS) $^

mdio: mdio.c
	$(CC) -o $@ -static -Wall $(CFLAGS) $(CPPFLAGS) $^

clean:
	rm -vf $(BINS)

.PHONY: clean
