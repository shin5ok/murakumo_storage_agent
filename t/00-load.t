#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Murakumo::Storage_Agent' ) || print "Bail out!\n";
}

diag( "Testing Murakumo::Storage_Agent $Murakumo::Storage_Agent::VERSION, Perl $], $^X" );
