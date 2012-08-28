use strict;
use warnings;
use Test::More tests => 2;

BEGIN { use_ok('List::Vectorize') }

my $w = which([0, 0, 1, 1, 0, 1]);

is_deeply($w, [2, 3, 5]);
