#set terminal postscript landscape enhanced color
#set output '| ps2pdf - diagram.pdf'
set terminal pdf size 8.27,11.69
set size 0.8,0.4
set origin 0.1,0.3
set title " Population vs time" font "Times-Roman, 18"
set xrange[0:xhigh]
set yrange[0:yhigh]
