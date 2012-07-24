#!/usr/bin/env perl
use strict;
use warnings;
use Carp;
use Data::Dump qw( dump );

use constant HAS_LEAKTRACE => eval { require Test::LeakTrace };
use Test::More HAS_LEAKTRACE
    ? ( tests => 1 )
    : ( skip_all => 'require Test::LeakTrace' );
use Test::LeakTrace;

use Plack::Test;
use Dezi::Server;

SKIP: {

    if ( !$ENV{DEZI_INDEX} ) {
        diag('must define DEZI_INDEX');
        skip 'must define DEZI_INDEX', 1;
    }

    leaks_cmp_ok {
        test_psgi(
            app => Dezi::Server->app(
                { engine_config => { index => $ENV{DEZI_INDEX} } }
            ),
            client => sub {
                my $callback = shift;
                my $i        = 0;
                while ( $i++ < 1 ) {
                    my $req = HTTP::Request->new( GET => "/search?q=test" );
                    my $resp = $callback->($req);
                }

            },
        );
    }
    '<', 1, "no dezi leaks";

}
