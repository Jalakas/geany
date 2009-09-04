#!/usr/bin/env perl
# Copyright:	2009, Nick Treleaven
# License:		GNU GPL V2 or later, as published by the Free Software Foundation, USA.
# Warranty:		NONE

# Re-align C source code for Geany.
# Doesn't handle indents/blank lines/anything complicated ;-)

use strict;
use warnings;

use Getopt::Std;

my %args = ();
getopts('w', \%args);
my $opt_write = $args{'w'};

my $argc = $#ARGV + 1;
my $scriptname = $0;

($argc == 1) or die <<END;
Usage:
$scriptname sourcefile [>outfile]
  Print formatted output to STDOUT or outfile.
  Warning: do not use the same file for both.

$scriptname -w sourcefile
  Writes to the file in-place.
  Warning: backup your file(s) first or use clean version control files.
END

# TODO: operate on multiple files
my ($infile) = @ARGV;
my @lines;

open(INPUT, $infile) or die "Couldn't open $infile for reading: $!\n";

while (<INPUT>) {
	my $line = $_;	# read a line, including \n char

	# strip trailing space & newline
	$line =~ s/\s+$//g;

	# for now, don't process lines with comments, strings, preproc, overflowed lines or chars
	# multi-line comments are skipped if they start with ' * '.
	if (!($line =~ m,/\*|\*/|//|"|\\$|',) and !($line =~ m/^\s*[*#]/)) {
		# make these operators have *one* space each side
		# operators must have longer variants first
		# some require special handling below
		my $ops = '<<=,<<,>>=,>>,<=,>=,<,||,|=,|,-=,+=,*=,/=,/,==,!=,%=,%,=';
		$ops =~ s/([|*+])/\\$1/g; # escape regex chars
		$ops =~ s/,/|/g;
		$line =~ s/($ops)\s*/$1 /g; # space after op
		$line =~ s/(\S)\s*($ops)/$1 $2/g; # space before op unless indent

		# &,*,+,-,> can be (part of) unary op
		# ignore no space after & address-of operator, enforce space around x & y operator
		# ignore lines starting with &, ambiguous.
		$line =~ s/([\w)])\s*&\s*([\w(]|$)/$1 & $2/g;
		# TODO: other possible unarys

		# space after statements
		my $statements = 'for|if|while|switch';
		$line =~ s/\b($statements)\b\s*/$1 /g;

		# no space on inside of brackets
		$line =~ s/\(\s+/(/g;
		$line =~ s/\s+\)/)/g;
	}
	# strip trailing space again (e.g. trailing operator now has space afterwards)
	$line =~ s/\s+$//g;

	$opt_write or print $line."\n";
	$opt_write and push(@lines, $line);
}
close(INPUT);

$opt_write or exit;

open(OUTPUT, ">$infile") or die "Couldn't open $infile for writing: $!\n";
foreach my $line (@lines)
{
	print OUTPUT $line."\n";
}
close(OUTPUT);
