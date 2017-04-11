# timefmt will only take effect if set xdata is also given
set ydata time
set timefmt "%s"
set format y "%d %H:%M"

set ytics nomirror

# date --date='2016-04-21 23:58:00' +%s
# date --date=@1461747768
#stime = 1463121600
#length =  600
#set yrange [stime: stime+length]
set xrange [0: 600]

#set terminal svg size 8000,4400 dynamic
set terminal svg size 4000,1400 dynamic
set output 'x.svg'

pingips = system("cat ip.ping.list")
iplist = system("cat ip.list")
set multiplot \
	layout 2,4 \
	columnsfirst \

fn(sip, ip) = sprintf('data/%s-ping-%s.out', sip, ip)
do for [ip in pingips] {
	plot for [sip in iplist] fn(sip, ip) using 2:1 with lines title fn(sip, ip)
}

unset multiplot
