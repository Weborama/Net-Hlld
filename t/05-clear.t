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

throws_ok(sub { $client->hll_clear('nethlldtest-foo') },
          'Net::Hlld::Exception::Action',
          q{... and an exception is thrown when trying to clear an open set});
is($@->action, 'clear',
   q{... and the exception has the correct value in the 'action' attribute});
is($@->message, 'Set is not proxied. Close it first.',
   q{... and the correct value in the 'message' attribute});

$client->hll_close('nethlldtest-foo');

lives_ok(sub { $client->hll_clear('nethlldtest-foo') },
         q{... and no exception is thrown when clearing a closed set});

done_testing;
