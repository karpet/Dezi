#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Dezi' );
}

diag( "Testing Dezi $Dezi::VERSION, Perl $], $^X" );
