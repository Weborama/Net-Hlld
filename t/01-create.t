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

use Net::Hlld;

my $socket = Net::Hlld::TestUtils::make_socket_to_local_instance();

unless ($socket) {
    plan 'skip_all', 'Set NETHLLDTESTHOST and PORT to test against a live instance';
}

my $client = Net::Hlld->new(socket => $socket);

lives_ok(sub { $client->hll_create('nethlldtest-foo') },
         q{... and creating a normal set always works by default});

throws_ok(sub { $client->hll_create('nethlldtest-foo', die_if_exists => 1) },
          'Net::Hlld::Exception::Action',
          q{... and we throw an exception if required when creating a set that already exists});
is($@->action, 'create',
   q{... and the exception has the correct value in the 'action' attribute});
is($@->message, 'Set already exists',
   q{... and the correct value in the 'message' attribute});

throws_ok(sub { $client->hll_create('nethlldtest-kame/hame/ha') },
          'Net::Hlld::Exception::Action',
          q{... and trying to create sets with bad names throws a generic action exception});
is($@->action, 'create',
   q{... and the exception has the correct value in the 'action' attribute});
# can't actually test the error message since none is documented.

done_testing;
