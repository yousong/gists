set ytics nomirror
set y2tics

plot \
		 "loan.60" using 1 with lines title "60 each", \
		 "loan.120" using 1 with lines title "120 each", \
		 "loan.60" using 2 with lines title "60 total"   axes x1y2, \
		 "loan.120" using 2 with lines title "120 total" axes x1y2, \
