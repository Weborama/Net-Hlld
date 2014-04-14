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

cmp_deeply([ values %set_list ],
           superbagof({ name => 'nethlldtest-foo',
                        epsilon => re(qr/[\d.]+/),
                        precision => re(qr/[\d.]+/),
                        storage => re(qr/\d+/),
                        size => re(qr/\d+/) }),
           q{... and the set list data contains the expected structure and infos});

%set_list = $client->hll_list('nethlldtest-foo');

cmp_deeply(\%set_list,
           { 'nethlldtest-foo' => { name => 'nethlldtest-foo',
                                    epsilon => re(qr/[\d.]+/),
                                    precision => re(qr/[\d.]+/),
                                    storage => re(qr/\d+/),
                                    size => re(qr/\d+/) } },
           q{... and the set list data contains the sole expected structure and infos});

done_testing;
