#!/bin/bash

CONTAINER=${1:-container}
FILENAME=${2:-filename}
COUNTER=${3:-seconds} 

if [ $# -gt 3 ]; then
  echo 1>&2 "$0: too many arguments"
  exit 2
elif [ $# -lt 2 ]; then
  echo 1>&2 "usage: $0 [container] [filename] or $0 [container] [filename] [seconds]"
  exit 2
fi

stats_command() {
    STATS=$(docker stats $CONTAINER --format "table {{.CPUPerc}} {{.MemUsage}} {{.BlockIO}}" --no-stream | sed 1d | sed 's/ \/ / /g' | sed 's/%//g' )
    DATE=$(date "+%T")
    CPU=$(echo $STATS | awk '{print $1}')
    MEM_USED=$(echo $STATS | awk '{ if(index($2, "GiB")) {gsub("GiB","",$2); print $2 * 1000} else {gsub("MiB","",$2); print $2}}')
    MEM_AVAIL=$(echo $STATS | awk '{ if(index($3, "GiB")) {gsub("GiB","",$3); print $3 * 1000} else {gsub("MiB","",$3); print $3}}')
    DISK_WRITE=$(echo $STATS | awk '{ if(index($4, "GB")) {gsub("GB","",$4); print $4 * 1000} else if(index($4, "kB")) {gsub("kB","",$4); print $4 / 1000} else {gsub("MB","",$4); print $4}}')
    DISK_READ=$(echo $STATS | awk '{ if(index($5, "GB")) {gsub("GB","",$5); print $5 * 1000} else if(index($5, "kB")) {gsub("kB","",$5); print $5 / 1000} else {gsub("MB","",$5); print $5}}')
    echo \"$DATE\" $CPU $MEM_USED $MEM_AVAIL $DISK_WRITE $DISK_READ >> $FILENAME
}

draw_charts() {
gnuplot -persist <<-EOFMarker
    set title "cpu usage"
    set xlabel "time"
    set ylabel "%"
    set datafile separator "  "
    set timefmt "%H:%M:%S"
    set xdata time
    set term png
    set output 'cpu.png'
    set key left top
    plot '$FILENAME' using 1:2 with lines title "cpu used"
EOFMarker

gnuplot -persist <<-EOFMarker
    set title "memory usage"
    set xlabel "time"
    set ylabel "MB"
    set datafile separator " "
    set timefmt "%H:%M:%S"
    set xdata time
    set term png
    set output 'memory.png'
    set key left bottom
    plot '$FILENAME' using 1:3 with lines title "memory-used", '$FILENAME' using 1:4 with lines title "memory total"
EOFMarker

gnuplot -persist <<-EOFMarker
    set title "disk io"
    set xlabel "time"
    set ylabel "MB"
    set datafile separator " "
    set timefmt "%H:%M:%S"
    set xdata time
    set term png
    set output 'disk.png'
    set key left top
    plot '$FILENAME' using 1:5 with lines title "disk_write", '$FILENAME' using 1:6 with lines title "disk read"
EOFMarker
}

cleanup() {
    draw_charts
    exit 0
}

echo "Saving results to file $FILENAME"

trap cleanup SIGINT SIGTERM

if [[ $COUNTER -gt 0 ]]
then
    echo "Running stats collection for $COUNTER seconds"
    while [ $COUNTER -gt 0 ]; do
        stats_command;
        sleep 1;
        let COUNTER=COUNTER-1
    done
    draw_charts
else
    echo "To exit press CTRL+C"
    while true; do
        stats_command;
        sleep 1 && wait $!
    done
fi
