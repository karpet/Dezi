use strict;
use warnings;
use inc::Module::Install;
use 5.008003;

name 'Dezi';
all_from 'lib/Dezi.pm';
requires 'Test::More'                       => 0;
requires 'Search::Tools'                    => '1.000';
requires 'Search::Query'                    => '0.300';
requires 'Search::Query::Dialect::Lucy'     => '0.201';
requires 'Lucy'                             => 0.003002;
requires 'Dezi::App'                        => 0.013;
requires 'SWISH::3'                         => '1.000013';
requires 'Search::OpenSearch::Engine::Lucy' => '0.400';
requires 'Search::OpenSearch::Server'       => '0.300';
requires 'Search::OpenSearch'               => '0.400';
requires 'Moose'                            => 0;
requires 'Type::Tiny'                       => 0;
requires 'Plack'                            => 0;
requires 'Class::Load'                      => 0;
requires 'Plack::Middleware::ReverseProxy'  => 0;
requires 'Plack::Middleware::Auth::Basic'   => 0;

# can't require in case Text::Aspell not available
recommends 'LucyX::Suggester' => '0.003';

perl_version '5.8.3';
license 'Perl_5';
homepage 'https://github.com/karpet/Dezi';
bugtracker 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Dezi';
repository 'http://github.com/karpet/Dezi';
install_script 'bin/dezi';

WriteMakefile(
    PL_FILES => {},
    dist     => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 't/test.index Dezi-* dezi.index' },
);
