use ExtUtils::MakeMaker;

WriteMakefile(
	NAME          => 'List::Vectorize',
	VERSION_FROM  => 'lib/List/Vectorize.pm',
	PREREQ_PM     => {
		'Data::Dumper' => "",
		'Test::More'   => "",
		'Carp'         => "",
	},
	AUTHOR        => 'Zuguang Gu <jokergoo@gmail.com>',
	ABSTRACT      => 'Functions for vectorized calculation',
	LICENSE       => 'perl',
);
