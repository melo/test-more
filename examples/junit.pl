#!/usr/bin/env perl

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib"; 
use Test::Builder2;
use Test::Builder2::Formatter::JUnit;
use Test::Builder;

my $fmt = Test::Builder2::Formatter::JUnit->create;
my $builder = Test::Builder2->singleton;
$builder->set_formatter($fmt);
Test::Builder->new->reset(Formatter => $fmt);

require $ARGV[0];
