package List::Vectorize;

use strict;

use Carp;
use Data::Dumper;
use constant {EPS => 1e-8};
require Exporter;

our @ISA = ("Exporter");

our $VERSION = "1.00";

our @EXPORT = qw(sapply mapply happly tapply initial_array initial_matrix order
                 rank sort_array reverse_array repeat rep copy paste seq c test 
                 unique subset subset_value which dim t matrix_prod is_array_identical 
                 is_matrix_identical outer inner match len abs plus minus multiply divide
                 print_ref print_matrix read_table write_table intersect union
                 setdiff setequal is_element sign sum mean geometric_mean 
                 sd var cov cor dist freq table scale sample del_array_item 
                 rnorm rbinom max min which_max which_min median quantile iqr cumf
                 is_empty
);

our %EXPORT_TAGS = (
     apply => [qw(sapply mapply happly tapply)],
     list  => [qw(initial_array initial_matrix order rank sort_array reverse_array
                  repeat rep copy paste seq c test unique subset subset_value
                  which dim t matrix_prod is_array_identical is_matrix_identical
                  outer inner match len is_empty del_array_item plus minus multiply divide)],
     io    => [qw(print_ref print_matrix read_table write_table)],
     set   => [qw(intersect union setdiff setequal is_element)],
     stat  => [qw(sign sum mean geometric_mean sd var cov cor dist freq table scale
                  sample rnorm rbinom max min which_max which_min
                  median quantile iqr cumf abs)]
);              

my $module = __PACKAGE__;
$module =~s/::/\//g;

# find the module library directory
my $module_dir = ".";
foreach (@INC) {
    if( -e "$_/$module.pm") {
        $module_dir = $_;
        last;
    }
}


use Carp;


our $REF_TYPE = {'SCALAR' => '$',
                 'ARRAY' => '@',
                 'HASH' => '%',
                 'CODE' => '&',
                 'GLOB' => '*',
                 'Regexp' => 'm',
                 'REF' => '$',
                 };
                 
# variable in @_ are all references
sub check_prototype {
    my $prototype = pop;
    my $prototype_as_string = $prototype;
    if(ref($prototype) ne "Regexp") {
        $prototype =~s/\\/\\\\/g;
        $prototype =~s/([\$\&\%\@\*])/\\$1/g;
        $prototype = qr/$prototype/;
    }
    
    my $p = '';
    for(my $i = 0; $i < scalar(@_); $i ++) {
        if(ref($_[$i])) {
            $p .= '\\'.$REF_TYPE->{ref($_[$i])};
        }
        else {
            $p .= $REF_TYPE->{ref(\$_[$i])};
        }
    }
    
    if($p=~/^$prototype$/) {
        return 1;
    }
    else {
        confess "ERROR: your prototype is '$p', but it should be '$prototype_as_string' ($prototype).\n";
    }
}



# get all functions
require("$module_dir/$module/lib/Apply.pl");
require("$module_dir/$module/lib/List.pl");
require("$module_dir/$module/lib/IO.pl");
require("$module_dir/$module/lib/Set.pl");
require("$module_dir/$module/lib/Statistic.pl");
require("$module_dir/$module/lib/Datatype.pl");


1;


__END__

=pod

=head1 NAME

List::Vectorize - functions to make vectorized calculation easy.

=head1 SYNOPSIS

  use List::Vectorize;               # export all functions
  use List::Vectorize qw(:apply);    # export apply family functions
  use List::Vectorize qw(:list);     # export functions that manuplate list
  use List::Vectorize qw(:set);      # export functions that manuplate sets
  use List::Vectorize qw(:stat);     # export functions that do statistical things
  use List::Vectorize qw(:io);       # export functions that print or read data

=head1 DESCRIPTION

The module implements some functions in R style. The motivation is to help perl
programming vectorized. And the module also provides a lot of functions to do basic statistic work.

=head2 Apply family functions

Apply family functions in R are used to apply functions on categories of data.
In this module, four apply functions are implemented. It can easily vectorize
the perl programming where the vectors are represented as array references.
However, the code may be a little hard to read.

=over 4

=item C<sapply(ARRAY_REF, CODE_REF)>

To apply a function on every element in the array. Maybe it is more proper to name
this function as C<apply>. But to be consistent with the same function in R where C<apply> is used
to apply functions on certain dimension of matrix and C<sapply> function
is used to apply function on every element of a vector. So we name
the function as C<sapply> here.

  my $a = [1..10];
  my $b = sapply($a, sub {1/$_[0]});
  print_ref $b;

The function returns an array reference whenever it has any element.

=item C<mapply(ARRAY_REF, ARRAY_REF, ..., CODE_REF)>

To apply a function on every element of the arrays parallel. This function is an
extension of C<sapply> and it can implement most of the vectorized calculation.

  my $x = [1..26];
  my $y = [1..26];
  # z = x^2 + 1/y + x*y
  my $z = mapply($x, $y, sub{$_[0]**2 + 1/$_[1] + $_[0]*$_[1]});
  print_ref $z;

We will show how to translate algorithms in R code into perl. The following
code is to calculate false discovery rate (FDR, BH process) in multiple test problem
(see source code of C<p.adjust> function).

  lp <- length(p)
  n <- length(p)
  i <- lp:1
  o <- order(p, decreasing = TRUE)
  ro <- order(o)
  pmin(1, cummin(n/i * p[o]))[ro]

To translate, we need to define a new function C<cummin> which is a cummulative minimum
of the elements in the vector. Anyway, we have already a function C<cumf> in this module
that can calculate cummulative values in the vector. Then the translation looks like:

  # p-values are stored in @$p
  # lp <- length(p)
  my $lp = len($p);
  my $n = $lp;
  # i <- 1p:1
  my $i = seq($lp, 1);
  # o <- order(p, decreasing = TRUE)
  my $o = order($p, sub {$_[1] <=> $_[0]});  # descreasing
  # ro <- order(o)
  my $ro = order($o);
  # n/i * p[o]
  my $foo1 = mapply($i, subset($p, $o), sub {$n/$_[0]*$_[1]})
  # cummin(n/i * p[o])
  my $foo2 = cumf($foo1, \&min);
  # pmin(1, cummin(n/i * p[o]))
  my $foo3 = sapply($foo2, sub {$_[0] < 1 ? $_[0] : 1});
  # ok, the finnal pmin(1, cummin(n/i * p[o]))[ro]
  my $adjp = subset($foo3, $ro);

=item C<happly(ARRAY_REF, CODE_REF)>

To apply a function on every element of the hash. If you take the hash as a named array,
then it is similar to the C<sapply> function. The function returns a hash reference.

  my $h = {"a" => 1, "b" => 2, "c" => 3};
  my $b = happly($h, sub {$_[0]**2});
  print_ref $b;

=item C<tapply(ARRAY_REF, ARRAY_REF, ..., CODE_REF)>

To apply a function on the elements of every catelogy according to the tabulation.
The first argument is the value array reference, the last argument is the code
reference, and the others are the array reference for tabulation. The function returns
a hash reference.

  my $x = [1..10];
  my $t1 = ["a", "a", "a", "a", "a", "b", "b", "b", "b", "b"];
  my $y = tapply($x, $t1, sub {sum(\@_)});
  print_ref $y;
  
  # or there may be more catogiry variables
  my $t2 = ["c", "c", "d", "d", "e", "e", "f", "f", "g", "g"];
  my $z = tapply($x, $t1, $t2, sub {sum(\@_)});
  print_ref $z;

=back
  
=head2 List functions

Functions to manuplate lists. Lists are represented as array references.

=over 4

=item C<len(ARRAY_REF | HASH_REF | SCALAR)>

If the argument is an array reference, then it returns the array's length. If it is a hash
reference, then returns the hash's value's length. If the argument is not defined, then 
returns 0, or else 1.

The function returns a number.

  print len([1..10]);
  print len({"a" => 1, "b" => 2});
  print len(undef);
  print len(1);

=item C<initial_array(SCALAR (size), SCALAR | CODE_REF (value) )>

Initialize an array with some values. The first argument is the size of the array
and the second argument is either a scalar or code reference. If it is a scalar,
the value of the scalar will be repeated to fill the array. If it is a code refence,
the value of the array will be generated by the code. By default, the second argument
is C<undef>. The functions returns an array reference.

  my $x = initial_array(10, sub{rand});
  print_ref $x;

=item C<initial_matrix(SCALAR (n_row), SCALAR (n_col), SCALAR | CODE_REF (value) )>

Initial a matrix. The arguments are similar to C<initial_array>.

The functions returns a matrix (reference of a two dimensional array reference).

  # a 2x2 matrix initialized with random numbers from uniform distribution in (0, 1)
  my $x = initial_matrix(10, 10, sub{rand});
  print_matrix $x;

=item C<order(ARRAY_REF (value), CODE_REF (sorting function) )>

Returns the order of the elements in the array. The function returns an array reference.
By default, the sorting function is to sort numbers. Variables C<$a> and C<$b> are replaces
with C<$_[0]> and C<$_[1]>.

  my $x = [3, 1, 14, 6, 26];
  my $o = order($x);
  print_ref $o;
  # if you want to sort the array descreasingly
  $o = order($x, sub {$_[1] <=> $_[0]});
  
  # sort as they are strings
  $o = order($x, sub {$_[0] cmp $_[1]);
  print_ref $o;

=item C<rank(ARRAY_REF (value) )>

Returns the rank of the elements in the array. The function returns an array reference.

=item C<sort_array(ARRAY_REF (value), CODE_REF (sorting function) )>

Sort the array. Arguments are similar to the C<order>.
The function returns an array reference.

=item C<reverse_array(ARRAY_REF (value) )>

Reverse the array.

=item C<repeat(SCALAR (value), SCALAR (size), SCALAR (need_copy) )>

Repeat a value or data structure. If the first argument is a reference, then the 
third argumetn is to specify whether make a copy of the real data that the reference
refer to or just repeat the address.

  my $x = repeat(1, 10);
  my $v = [1..10];   # reference
  $x = repeat($v, 10, 0);  # ten items all refer to a same address.
  $x = repeat($v, 10, 1);  # ten items have same values and independent.

=item C<rep(SCALAR (value), SCALAR (size), SCALAR (need_copy) )>

Same as C<repeat>.

=item C<copy(REF)>

copy a new data from a reference. The new data has the same values as the old data
but locates at different address.

  my $x = {a => [1, 2], b => [3, 4]};
  my $y = copy($x);  # change $y will not affect $x.

=item C<paste(ARRAY_REF | SCALAR, ARRAY_REF | SCALAR, ..., SCALAR (seperation) )>

Paste strings in arrays. If the last argument is a scalar and not a reference, it is used
as the seperation character. The default seperation character is "|". 

  my $x1 = "a";
  my $x2 = [1..10];
  my $x3 = ["+", "+", "+", "+", "+", "-", "-", "-", "-", "-"];
  my $y = paste($x1, $x2, $x3, "");

=item C<seq(SCALAR (from), SCALAR (to), SCALAR (by) )>

Generate a list of numbers.

  my $x = seq(1, 10);
  $x = seq(1, 10, 2);

=item C<c(ARRAY_REF | SCALAR, ...)>

combine values into an array, only array reference and scalar is permitted.

  my $x = c([1..10], 11, [12..15]);

=item C<test(ARRAY_REF, CODE_REF)>

Test whether the values meet the condition of the function. The function returns
an array reference.

  my $x = seq(-5, 5);
  my $l = test($x, sub {$_[0] > 0});

=item C<unique(ARRAY_REF)>

unify the array

=item C<subset(ARRAY_REF, ARRAY_REF | CODE_REF)>

Get the subset of an array. If the second argument is number, positive number means
to get the value and negative number means to drop the value. The second argument
can also be function to test whether the values in the array meet the condition.
Note using 0|1 as the value of the array in the second argument does not means take 
values in the corresponding posotion or not. Using 0|1 directly only means take values
in the first or the second position of the array. If you want to take 0|1 as logical 
variable, use C<which> function.

  my $x = seq(-5, 5);
  my $s = subset($x, sub{$_[0] > 0});
  $s = subset($x, [1, 2, 3]);
  $s = subset($x, [-1, -2, -3]);
  $s = subset($x, [1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0]);
  $s = subset($x, which([1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0]));

=item C<subset_value(ARRAY_REF, ARRAY_REF | CODE_REF, ARRAY_REF | SCALAR)>

Change subset values. The first and the second arguments are similar to the C<subset>,
and the third argument is the value that will replace the value in the origin array. It can
be either an array reference having the same length as the position having true values or
a scalar.

  my $x = seq(-5, 5);
  subset_value($x, sub{$_[0] > 0}, 0);
  print_ref $x;
  
=item C<del_array_item(ARRAY_REF, SCALAR | ARRAY_REF)>

Delete items in an array.

  my $x = [1..10];
  del_array_item($x, 2);
  del_array_item($x, [1, 3, 5]);

=item C<which(ARRAY_REF)>

Return the index having true values.

  my $x = seq(-5, 5);
  my $l = test($x, sub {$_[0] > 0});
  my $w = which($l);

=item C<all(ARRAY_REF)>

Test whether all items are true

=item C<any(ARRAY_REF)>

Test whether at least one of the items is true

=item C<match(ARRAY_REF, ARRAY_REF)>

Find the index of the first array that can be found in the second array.

  my $x1 = ["a", "b", "c"];
  my $x2 = ["b", "c", "d"];
  my $m = match($x1, $x2);
  $m = match($x2, $x1);

=item C<dim(ARRAY_REF)>

Dimensions of the matrix

  my $m = [[1,2],[3,4]];
  print dim($m);

=item C<t(ARRAY_REF)>

Transpose the matrix.

  my $m = [[1,2],[3,4]];
  print_matrix $m;
  my $t = t($m);
  print_matrix($t);

=item C<matrix_prod(ARRAY_REF,ARRAY_REF, ...)>

Product a list of matrixes.

  my $m = [[1,2],[3,4]];
  print_matrix matrix_prod($m, $m, $m);

=item C<inner(ARRAY_REF, ARRAY_REF, CODE_REF)>

Inner function on two arrays. The same as the sum of C<mapply> with two arrays. The default function is
production.

=item C<outer(ARRAY_REF, ARRAY_REF, CODE_REF)>

Outer function on two arrays. The default function is production.

  my $x = [1..10];
  my $y = [1..10];
  # z = sin(xy)
  my $z = outer($x, $y, sub {sin($_[0]*$_[1])});
  print_matrix $z;

=item C<is_array_identical(ARRAY_REF,ARRAY_REF)>

whether the two arrays are similarly same.

=item C<is_matrix_identical(ARRAY_REF,ARRAY_REF)>

whether the two matrixes are similarly same.

=item C<is_empty(ARRAY_REF)>

whether the reference is empty.

=item C<plus(ARRAY_REF, ARRAY_REF, ...)>

plus of arrays

  my $r = plus([1..10], [2..11], 2);

=item C<minus(ARRAY_REF, ARRAY_REF, ...)>

minus of arrays

=item C<multiply(ARRAY_REF, ARRAY_REF, ...)>

multiply of arrays

=item C<divide(ARRAY_REF, ARRAY_REF, ...)>

divide of arrays

=back

=head2 Set operation functions

=over 4

=item C<intersect(ARRAY_REF, ARRAY_REF, ...)>

Intersection of a list of arrays.

  my $x = ["a", "b", "c", "d"];
  my $y = ["b", "c", d", "e"];
  my $x = ["c", "d", "a", "g"];
  my $d = intersect($x, $y, $z);

=item C<union(ARRAY_REF, ARRAY_REF, ...)>

Union of a list of arrays.

  my $x = ["a", "b", "c", "d"];
  my $y = ["b", "c", d", "e"];
  my $x = ["c", "d", "a", "g"];
  my $d = union($x, $y, $z);

=item C<setdiff(ARRAY_REF, ARRAY_REF)>

Items exist in the first set while not in the second set.

  my $x = ["a", "b", "c", "d"];
  my $y = ["b", "c", d", "e"];
  my $d = setdiff($x, $y);

=item C<setequal(ARRAY_REF, ARRAY_REF)>

whether the two arrays are equal.

=item C<is_element(SCALAR, ARRAY_REF)>

whether the element is in the set

  my $x = ["a", "b", "c", "d"];
  print is_element("a", $x);

=back  

=head2 Input and output functions

=over 4

=item C<print_ref(REF)>

print the data structure of the reference.

  my $a = [1..10];
  print_ref $a;

=item C<print_matrix(ARRAY_REF)>

print the content of the matrix. 

=item C<read_table(SCALAR, HASH)>

read matrix from file. The first argumetn is the path of the file. The other
arguments are as follows.

  quote       charector to quote the value (no quoting)
  sep         seperation character (\t)
  col.names   whether take first column as column names
  row.names   whether take first row as row names
  col.skip    columns being skipped, array ref, start with 1
  row.skip    rows being skipped, array ref, start with 1

The function return a list with three elements: colnames, rownames, and the data matrix

=item C<write_table(ARRAY_REF, HASH)>

write data to file. The first argument is a data matrix. The other arguments
are as follows.

  quote       charector to quote the value (no quoting)
  sep         seperation character (\t)
  col.names   array reference of the column names (optional)
  row.names   array reference of the row names (optional)
  file        file name

For example

  my $x = [[1,2], [3,4]];
  my $colnames = ["c1", "c2"];
  my $rownames = ["r1", "r2"];
  write_table($x, "file" => "file.txt",
                  "quote" => "\"",
                  "sep" => "\t",
                  "col.names" => $colnames,
                  "row.names" => $rownames,);

=back

=head2 Statistical functions

=over 4

=item C<abs($value)>

return the absolute value

=item C<sign($value)>

return the sign of a value

=item C<sum(ARRAY_REF)>

Summmation of a list of numbers. The numbers should be stored as an array reference.

=item C<prod(ARRAY_REF)>

Production of a list of numbers.

=item C<mean(ARRAY_REF)>

Mean value of a list of numbers.

=item C<geometric_mean(ARRAY_REF)>

Geometric mean value of a list of numbers.

=item C<sd(ARRAY_REF)>

Standard deviation of a list of numbers.

=item C<var(ARRAY_REF)>

Variance of a list of numbers.

=item C<cov(ARRAY_REF, ARRAY_REF)>

Coviarance of two vectors.

=item C<cor(ARRAY_REF, ARRAY_REF, SCALAR)>

Correlation coefficient of two vectors. The third argument is "pearson" or "spearman".

=item C<dist(ARRAY_REF, ARRAY_REF, SCALAR)>

Distance between two vectors. Several definition of the distance is provided.

  euclidean  Euclidean distance
  person     Person correlation coefficient
  spearman   Spearman correlation coefficient
  logical    It is defined as 1/(1+k) where k is the number of items that are both ture in two vectors.

=item C<freq(ARRAY_REF, ARRAY_REF, ...)>

Frequency of the items in an array or arrays. Returns a hash reference.

  my $a = ["a", "a", "a", "a", "b", "b", "b", "b"];
  my $b = ["1", "2", "1", "2", "1", "2", "1", "2"];
  print_ref freq($a);
  print_ref freq($a, $b);

=item C<table(ARRAY_REF, ARRAY_REF, ...)>

The same as C<freq>, to be consist with R

=item C<scale(ARRAY_REF, SCALAR)>

Scale the vector based on some criterion.

  zvalue        vector has mean value of 0 and variance of 1
  percentage    values in the vector are between 0 - 1
  sphere        format the n-dimensional point on the surface of the unit super sphere

=item C<sample(ARRAY_REF, SCALAR (size), HASH)>

Random samplings and permutations. 

  my $x = ["a".."g"];
  # sample without replacement
  sample($x, 5);
  # permutation
  sample($x, len($x));
  # sample with replacement
  sample($x, 5, "replace" => 1);
  # sample with unequal probability
  # normalization of the p-values will be done automatically
  sample($x, 5, "p" => [10, 1, 1, 1, 1, 1, 1]);

=item C<rnorm(SCALAR (size), SCALAR (mean), SCALAR (sd))>

Generate random numbers from normal distribution.

  my $x = rnorm(10);
  $x = rnorm(10, 1, 2);

=item C<rbinom(SCALAR (size), SCALAR (p-value for success))>

Generate random numbers from binominal distribution. P-value is 0.5 by default.

  my $x = rbinom(10, 0.1)

=item C<max(ARRAY_REF)>

Maximum value in a vector

=item C<min(ARRAY_REF)>

Minimum value in a vector

=item C<which_max(ARRAY_REF)>

Find the index of the maximum value in the array. If there are several maximum values,
only the take the first one.

=item C<which_min(ARRAY_REF)>

Find the index of the minimum value in the array. If there are several minimum values,
only the take the first one.

=item C<median(ARRAY_REF)>

Median value in a vector.

=item C<quantile(ARRAY_REF, ...)>

quantile, the second argument can be a single p-value or a list of p-values storted in an array reference.
The return value type is same as the second argument.

  my $x = rnorm(100);
  my $q = quantile($x, 0.5);
  $q = quantile($x, [0.25, 0.75]);

=item C<iqr(ARRAY_REF)>

Inter quantile range. It is the distance between the 25th and the 75th quantiles.

=item C<cumf(ARRAY_REF, CODE_REF)>

cummulative function on an array. If you want to calculte the empirical cumularive
distribution. The function take array reference as argument.

  my $x = rnorm(10);
  my $sum = sum($x);
  my $ecdf = cumf($x, sub {sum($_[0])/$sum});

=back

=head1 AUTHOR

Zuguang Gu E<lt>jokergoo@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2012 by Zuguang Gu

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.12.1 or,
at your option, any later version of Perl 5 you may have available.

=cut
