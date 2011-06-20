use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Dezi',
    AUTHOR              => q{Peter Karman <karman@cpan.org>},
    VERSION_FROM        => 'lib/Dezi.pm',
    ABSTRACT_FROM       => 'lib/Dezi.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Dezi-*' },
);
