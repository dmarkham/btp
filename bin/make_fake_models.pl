#!/usr/bin/perl

use strict;
use Getopt::Long;

my $number;    # number of files
my $size;      # size of each file
my $max = 1;   # max value to perdict
my $min = 0;   # min value to perdict
&GetOptions('number=n' => \$number,
            'size=n'   => \$size,
            'max=f'    => \$max,
            'min=f'    => \$min,
           ) or exit -1;

print "building $number files that have $size records + a header\n";
for (my $i = 0 ; $i < $number ; $i++) {
  my $score = sprintf("%.6f", rand());               # model fake score
  my $file = "../data/fake_submission_$score.csv";
  print "Building $file\n";
  open(TEMP, ">$file");
  print TEMP join(",", "id", "trade_price") . "\n";

  for (my $y = 0 ; $y < $size ; $y++) {
    ## make a fake prediction
    my $value = sprintf("%.4f", rand($max - $min) + $min);
    print TEMP join(",", $y + 1, $value) . "\n";
  }
  close(TEMP);
}
print "Done\n";
