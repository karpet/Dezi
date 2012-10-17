use strict;
use warnings;
use inc::Module::Install;
use 5.008003;

name 'Dezi';
all_from 'lib/Dezi.pm';
requires 'Test::More'                       => 0;
requires 'Search::Query'                    => 0.21;
requires 'Search::Query::Dialect::Lucy'     => 0.05;
requires 'Lucy'                             => 0.003002;
requires 'SWISH::Prog'                      => 0.64;
requires 'Search::OpenSearch::Engine::Lucy' => 0.12;
requires 'Search::OpenSearch::Server'       => 0.21;
requires 'Search::OpenSearch'               => 0.23;
requires 'Plack'                            => 0;
requires 'Module::Load'                     => 0.22;
requires 'Plack::Middleware::ReverseProxy'  => 0;
requires 'Plack::Middleware::Auth::Basic'   => 0;

perl_version '5.8.3';
license 'http://dev.perl.org/licenses/';
homepage 'https://github.com/karpet/Dezi';
bugtracker 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Dezi';
repository 'http://github.com/karpet/Dezi';
install_script 'bin/dezi';

WriteMakefile(
    PL_FILES => {},
    dist     => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 't/test.index Dezi-* dezi.index' },
);
