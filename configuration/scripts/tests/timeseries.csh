#!/bin/csh

# Check to see if test case directory was passed
if ( $1 == "" ) then
  echo "To generate timeseries plots, this script must be called with a filename."
  echo "Example: ./timeseries.csh /work/username/case01/ice_diag.itd"
  exit -1
endif

#set basename = `echo $1:t`
set basename = $1

set fieldlist=("area fraction  " \
               "avg ice thickness (m)" \
               "avg snow depth (m)")

# Get the filename for the latest log
set logfile = $1

# Loop through each field and create the plot
foreach field ($fieldlist:q)
  set fieldname = `echo "$field" | sed -e 's/([^()]*)//g'`
  # Create the new data file that houses the timeseries data
  awk -v field="$fieldname" \
      '$0 ~ field {count++; print int(count/24)+1"-"count % 24 ","$(NF-1)","$NF}' \
      $logfile > data.txt

  set output = `echo $fieldname | sed 's/ /_/g'`
  set output = "${basename}_${output}.png"

  echo "Plotting data for '$fieldname' and saving to $output"

# Call the plotting routine, which uses the data in the data.txt file
gnuplot << EOF > $output
# Plot style
set style data points

set datafile separator ","

# Term type and background color, canvas size
set terminal png size 1920,960

# x-axis 
set xdata time
set timefmt "%j-%H"
set format x "%Y/%m/%d"

# Axis tick marks
set xtics rotate

set title "Annual ICEPACK Test $field (Diagnostic Print)" 
set ylabel "$field" 
set xlabel "Simulation Day" 

set key left top

plot "data.txt" using (timecolumn(1)-63072000):2 with lines lw 2 lt 3 title "Arctic", \
     "" using (timecolumn(1)-63072000):3 with lines lw 2 lt 1 title "Antarctic"
EOF

# Delete the data file
rm data.txt
end
