use strict;
use warnings;
use Test::More tests => 3;

BEGIN { use_ok('List::Vectorize') }

my $s = ["a", "b", "c", "d", "e"];

is(is_element("a", $s), 1);
is(is_element("g", $s), 0);
