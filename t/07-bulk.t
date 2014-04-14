#!/usr/bin/env perl

use strict;
use warnings;
use 5.010;
use Carp;
use autodie;
use utf8;

use lib 't/lib';
use Net::Hlld::TestUtils;

use Scalar::Util qw/blessed/;

use Test::More;
use Test::Exception;

use Net::Hlld;

my $socket = Net::Hlld::TestUtils::make_socket_to_local_instance();

unless ($socket) {
    plan 'skip_all', 'Set NETHLLDTESTHOST and PORT to test against a live instance';
}

my $client = Net::Hlld->new(socket => $socket);

eval {
    $client->hll_drop('nethlldtest-foo');
};

if (my $exception = $@) {
    unless (blessed $exception
        and $exception->isa('Net::Hlld::Exception::Action')) {
        die $exception;
    }
}

Net::Hlld::TestUtils::ensure_set_created($client, 'nethlldtest-foo');

my %set_info = $client->hll_info('nethlldtest-foo');
is($set_info{size}, 0,
   q{... and initially a set is empty})
    or diag(explain(\%set_info));

lives_ok(sub { $client->hll_bulk('nethlldtest-foo', qw/a b c d e f a b c/) },
         q{... and we can add multiple elements});

%set_info = $client->hll_info('nethlldtest-foo');
is($set_info{size}, 6,
   q{... and we can count them});

lives_ok(sub { $client->hll_bulk('nethlldtest-foo', qw/a b c/) },
         q{... and we can add multiple elements});

%set_info = $client->hll_info('nethlldtest-foo');
is($set_info{size}, 6,
   q{... and we can count them});

done_testing;
