package Net::Hlld::TestUtils;

use strict;
use warnings;
use 5.010;
use Carp;
use autodie;
use utf8;

use Scalar::Util qw/blessed/;
use Test::More;
use IO::Socket::INET;

sub make_socket_to_local_instance {
    unless ($ENV{'NETHLLDTESTHOST'}
            and $ENV{'NETHLLDTESTPORT'}) {
        return;
    }
    return IO::Socket::INET->new(PeerHost => $ENV{'NETHLLDTESTHOST'},
                                 PeerPort => $ENV{'NETHLLDTESTPORT'},
                                 Proto => 'tcp');
}

sub ensure_set_created {
    my ($client, $set_name) = @_;
    RETRY:
    while (1) {
        eval { $client->hll_create($set_name) };
        if (my $exception = $@) {
            if (blessed $exception
                    and $exception->can('temporary')
                    and $exception->temporary) {
                diag 'trying to recreate a dropped set faster than the daemon can cope...';
                sleep 1;
                next RETRY;
            }
            $exception->throw if blessed $exception;
            die $exception;
        } else {
            # success!
            last;
        }
    }
}

1;
