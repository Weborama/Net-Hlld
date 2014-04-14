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

throws_ok(sub { $client->hll_info('nethlldtest-foo') },
          'Net::Hlld::Exception::Action',
          q{... and although info usually emits a multiline response, we can still catch single-line errors});

# we've been using hll_info all this time to test for set size, no
# need for more tests

done_testing;
