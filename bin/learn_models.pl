#!/usr/bin/perl
use strict;
use Getopt::Long;
use Data::Dumper;
my $name;
my $buckets = 50;
GetOptions('name=s'    => \$name,
           'buckets=i' => \$buckets,
          ) or exit -1;

my $some_dir = "../data/";

opendir(my $dh, $some_dir) || die "can't opendir $some_dir: $!";
my @files = grep {/^$name/ && -f "$some_dir/$_"} readdir($dh);
closedir $dh;

warn "found files\n" . Dumper(\@files);

my %models;

## read in all the model data
my $test_file = "train_part_test.csv";
$models{$test_file} = return_values($test_file, 2);

my $w = return_values($test_file, 3);
my @weights = @{$w};
foreach my $file (@files) {
  $models{$file} = return_values($file);
}

my $min = 1_000_000;
my $max = -1_000_000;
my $avg;
for (my $i = 0 ; $i < scalar(@{$models{$test_file}}) ; $i++) {

  if ($models{$files[0]}->[$i] < $min) {
    $min = $models{$files[0]}->[$i];
  }
  if ($models{$files[0]}->[$i] > $max) {
    $max = $models{$files[0]}->[$i];
  }
  $avg = $avg + $models{$files[0]}->[$i];
}
$avg = $avg / scalar(@{$models{$test_file}});

my $span_size = ($max - $min) / $buckets;

print join("\t", "Min:$min", "Max:$max", "Avg:$avg", "Span Size$span_size") . "\n";

## build groups
my @span_ids;
for (my $i = 0 ; $i < scalar(@{$models{$test_file}}) ; $i++) {
  my $span = int($models{$files[2]}->[$i] / $span_size);
  push @{$span_ids[$span]}, $i;
}

my $data = get_score(@span_ids);
print Dumper($data);
my $score = sprintf("%.6f", $data->{score});
my $file = "../models/${name}_ensemble_${score}.csv";
open(TEMP, ">$file") || die $!;
for (my $i = 0 ; $i < scalar(@span_ids) ; $i++) {
  if ($data->{models}{$i}) {
    my $f = $data->{models}{$i};
    $f =~ s/\.csv//;
    print TEMP  "$f\n";
  } else {
    my $f = $files[0];
    $f =~ s/\.csv//;
    print TEMP "$f\n";
  }
}
close(TEMP);
exit;

#print Dumper($data);
##
##
##
##
##

sub get_score {
  my @span_ids = @_;

  #print Dumper(\@span_ids);
  my %scores;
  my %best;
  my $s = 1;
  foreach my $span_list (@span_ids) {
    my $weight;
    if (!$span_list) {
      next;
    }
    foreach my $i (@{$span_list}) {
      $weight = $weights[$i];
      foreach my $file ("train_part_test.csv", @files) {
        $scores{$s}{$file} = $scores{$s}{$file} + abs($models{$file}->[$i] - $models{"$test_file"}->[$i]) * $weight;
        $scores{'all'}{$file}
          = $scores{'all'}{$file} + abs($models{$file}->[$i] - $models{"$test_file"}->[$i]) * $weight;
        $scores{$s}{weight}{$file} = $scores{$s}{weight}{$file} + $weight;
        $scores{all}{weight}{$file} = $scores{all}{weight}{$file} + $weight;
      }
    }

    ## look for best
    my $best_file;
    my $best_min;
    foreach my $file (@files) {
      my $temp_score = $scores{$s}{$file} / $scores{$s}{weight}{$file};
      if (!$best_file || $best_min > $temp_score) {
        $best_file = $file;
        $best_min  = $temp_score;
      }
    }
    $scores{best} = $scores{best} + $scores{$s}{$best_file};
    $scores{'weight'} = $scores{'weight'} + $scores{$s}{'weight'}{$best_file};
    foreach my $file ("train_part_test.csv", @files) {
      $scores{$s}{$file} = $scores{$s}{$file} / $scores{$s}{weight}{$file};
      print "$file\t$scores{$s}{$file}\n";
    }
    my $bucket_count = scalar(@{$span_list});
    my $span_start   = ($s - 1) * $span_size;
    my $span_stop    = $span_start + $span_size;
    print "WINNER -->> $best_file\t$best_min\tItems:$bucket_count\tspan_start:$span_start\tspan_stop:$span_stop\n";
    $best{$s} = $best_file;
    $s++;
    print "\n\n";
  }

  print "ALL\n";
  foreach my $file ("train_part_test.csv", @files) {
    $scores{'all'}{$file} = $scores{'all'}{$file} / $scores{all}{weight}{$file};
    print "$file\t$scores{'all'}{$file}\n";
  }

  #print "Best\n";
  $scores{'best'} = $scores{best} / $scores{weight};

  #print "best\t$scores{best}\n";
  #print Dumper(\%best);
  return {buckets => $buckets, score => $scores{best}, models => \%best};
}

for (my $i = 0 ; $i < scalar(@{$models{$test_file}}) ; $i++) {
  foreach my $file ("train_part_test.csv", @files) {
    print "$models{$file}->[$i]\t";
  }
  print "\n";
}

## give a file and a field number return the values
sub return_values {
  my $file = shift;
  my $field = shift || 1;
  open(TEMP, "<$some_dir/$file") || die "Cant read file $!";
  my $header = <TEMP>;
  my @values;
  while (<TEMP>) {
    chomp($_);
    my @line = split("\,", $_);
    push @values, $line[$field];
  }
  return \@values;
}
