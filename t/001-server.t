#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 20;
use Plack::Test;
use HTTP::Request;
use JSON;
use Data::Dump qw( dump );

use_ok('Dezi::Server');

ok( my $app = Dezi::Server->app(
        {   search_path   => 's',
            index_path    => 'i',
            engine_config => {
                indexer_config =>
                    { config => { 'FuzzyIndexingMode' => 'Stemming_en1', }, },
            }
        }
    ),
    "new Plack app"
);

test_psgi(
    app    => $app,
    client => sub {
        my $cb  = shift;
        my $req = HTTP::Request->new( GET => 'http://localhost/s' );
        my $res = $cb->($req);
        is( $res->content, qq/'q' required/, "missing 'q' param" );
        is( $res->code, 400, "bad request status" );
    }
);

test_psgi(
    app    => $app,
    client => sub {
        my $cb = shift;
        my $req = HTTP::Request->new( PUT => 'http://localhost/s/foo/bar' );
        $req->content_type('application/xml');
        $req->content('<doc><title>i am a test</title></doc>');
        $req->content_length( length( $req->content ) );
        my $res = $cb->($req);

        #dump $res;
        #diag( $res->content );
        ok( my $json = decode_json( $res->content ),
            "decode content as JSON" );

        #dump $json;
        is( $json->{success}, 0,   "405 json response has success=0" );
        is( $res->code,       405, "PUT not allowed to /s" );
    }
);

test_psgi(
    app    => $app,
    client => sub {
        my $cb = shift;
        my $req = HTTP::Request->new( PUT => 'http://localhost/i/foo/bar' );
        $req->content_type('application/xml');
        $req->content(
            '<doc><title>i am a test</title>tester testing test123</doc>');
        $req->content_length( length( $req->content ) );
        my $res = $cb->($req);

        #dump $res;
        #diag( $res->content );
        ok( my $json = decode_json( $res->content ),
            "decode content as JSON" );

        #dump $json;
        is( $json->{doc}->{title}, 'i am a test', "test title" );
        is( $res->code,            201,           "PUT ok" );
    }
);

test_psgi(
    app    => $app,
    client => sub {
        my $cb  = shift;
        my $req = HTTP::Request->new( GET => 'http://localhost/s?q=test' );
        my $res = $cb->($req);
        ok( my $results = decode_json( $res->content ),
            "decode_json response" );

        #dump $results;
        is( $results->{query}, "test", "query param returned" );
        cmp_ok( $results->{total}, '==', 1, "more than one hit" );
        ok( exists $results->{search_time}, "search_time key exists" );
        is( $results->{title}, qq/OpenSearch Results/, "got title" );
        if ( defined $results->{suggestions} ) {
            is_deeply(
                $results->{suggestions},
                [ 'test', 'test123', 'tester' ],
                "got 3 suggestions, testing stemmed to test"
            );
        }
        else {
            pass("suggester not available");
        }
    }
);

test_psgi(
    app    => $app,
    client => sub {
        my $cb = shift;
        my $req
            = HTTP::Request->new( DELETE => 'http://localhost/i/foo/bar' );
        my $res = $cb->($req);

        #dump $res;
        ok( my $json = decode_json( $res->content ),
            "decode content as JSON" );

        #dump $json;
        is( $res->code, 200, "DELETE ok" );
    }
);

test_psgi(
    app    => $app,
    client => sub {
        my $cb  = shift;
        my $req = HTTP::Request->new( GET => 'http://localhost/s?q=test' );
        my $res = $cb->($req);
        ok( my $json = decode_json( $res->content ),
            "decode content as JSON" );
        is( $json->{total}, 0, "DELETE worked" );
    }
);
