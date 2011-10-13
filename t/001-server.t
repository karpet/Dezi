#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 16;
use Plack::Test;
use HTTP::Request;
use JSON;
use Data::Dump qw( dump );

use_ok('Dezi::Server');

ok( my $app = Dezi::Server->app(
        {   search_path => 's',
            index_path  => 'i',
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
        my $req = HTTP::Request->new( PUT => 'http://localhost/i/foo/bar' );
        $req->content_type('application/xml');
        $req->content('<doc><title>i am a test</title></doc>');
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
        is( $results->{query}, "test", "query param returned" );
        cmp_ok( $results->{total}, '==', 1, "more than one hit" );
        ok( exists $results->{search_time}, "search_time key exists" );
        is( $results->{title}, qq/OpenSearch Results/, "got title" );
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
        is( $res->code, 204, "DELETE ok" );
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
