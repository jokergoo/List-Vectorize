use strict;
use Test::More tests => 5;

BEGIN {
	use_ok('List::Vectorize');
    eval 'use Test::Exception';
}

my $a = [-5..5];
my $b = sapply($a, \&abs);
my $c = sapply($a, sub {$_[0]**2});
my $d = sapply($a, sub {[1, 2]});

SKIP: {

	skip('Test::Exception not installed', 1) if ($@);
	dies_ok { sapply($a, sub {1/$_[0]}) } "zero can not be divided.";
	
}


is_deeply($b, [5, 4, 3, 2, 1, 0, 1, 2, 3, 4, 5]);
is_deeply($c, [25, 16, 9, 4, 1, 0, 1, 4, 9, 16, 25]);
is_deeply($d, [[1, 2],
               [1, 2],
			   [1, 2],
               [1, 2],
			   [1, 2],
               [1, 2],
			   [1, 2],
               [1, 2],
			   [1, 2],
			   [1, 2],
               [1, 2],]);
