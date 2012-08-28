use strict;
use warnings;
use Test::More tests => 3;

BEGIN { use_ok('List::Vectorize') }

my $m1 = [[1,2],[3,4]];
my $m2 = [[1,2],[3,4]];

my $is = is_matrix_identical($m1, $m2) + 0;
is($is, 1);

$m2 = c($m2, \[5, 6]);
$is = is_matrix_identical($m1, $m2) + 0;
is($is, 0);
