#!/usr/bin/env perl

use strict;
use warnings;
use 5.010;
use Carp;
use autodie;
use utf8;

use lib 't/lib';
use Net::Hlld::TestUtils;

use Test::More;
use Test::Exception;
use Test::Deep;

use Net::Hlld;

my $socket = Net::Hlld::TestUtils::make_socket_to_local_instance();

unless ($socket) {
    plan 'skip_all', 'Set NETHLLDTESTHOST and PORT to test against a live instance';
}

my $client = Net::Hlld->new(socket => $socket);

$client->hll_create('nethlldtest-foo');

my %set_list = $client->hll_list;

ok(exists($set_list{'nethlldtest-foo'}),
   q{... and before being dropped a set is still in the list});

$client->hll_drop('nethlldtest-foo');

%set_list = $client->hll_list;

ok(not(exists($set_list{'nethlldtest-foo'})),
   q{... and after being dropped a set is no longer in the list});

done_testing;
