typedef unsigned int ipaddr;
struct iprange {
	ipaddr start;
	ipaddr end;
};

// Check if the supplied IP address is part of any IP ranges.
int find_ipaddr(struct iprange set[], int n, ipaddr ip)
{
	int left, right, mid;
	/* empty set */
	if (n < 1) {
		return -1;
	}
	/* ip is to the left of the whole set */
	if (set[0].start > ip) {
		return -1;
	}
	/* ip is to the right of the whole set */
	if (set[n - 1].end < ip) {
		return -1;
	}
	/* ip is in the last range */
	if (set[n - 1].start <= ip) {
		return n - 1;
	}

	/* The invariant:
	 *
	 *  - set[left].start <= ip
	 *  - set[right].start > ip
	 *
	 * So the result if there is one must be in set[left].
	 */
	left = 0;
	right = n - 1;
	while (left <= right) {
		mid = left + (right - left) / 2;
		if (ip < set[mid].start) {
			right = mid - 1;
		} else if (ip > set[mid].end) {
			left = mid + 1;
		} else {
			return mid;
		}
	}
	return -1;
}
