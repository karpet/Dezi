use strict;
use warnings;
use inc::Module::Install;
use 5.008003;

name 'Dezi';
all_from 'lib/Dezi.pm';
requires 'Test::More'                       => 0;
requires 'Search::Query::Dialect::Lucy'     => 0.04;
requires 'Lucy'                             => 0.001000;
requires 'Search::OpenSearch::Engine::Lucy' => 0.03;
requires 'Search::OpenSearch::Server'       => 0.08;
requires 'Search::OpenSearch'               => 0.14;
requires 'Plack'                            => 0;

perl_version '5.8.3';
license 'http://dev.perl.org/licenses/';
homepage 'https://github.com/karpet/Dezi';
bugtracker 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Dezi';
repository 'git://github.com/karpet/Dezi.git';
install_script 'bin/dezi';

WriteMakefile(
    PL_FILES => {},
    dist     => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Dezi-* dezi.index' },
);
