package Net::Hlld::MockServer;

use strict;
use warnings;
use 5.010;
use Carp;
use autodie;
use utf8;

use File::Temp;

use Moo;

has 'socket' => (is => 'ro',
                 lazy => 1,
                 builder => '_build_socket');
has 'socket_path' => (is => 'ro',
                      lazy => 1,
                      builder => '_build_socket_path');

has 'teleprompter' => (is => 'ro',
                       default => sub { [] });

sub _build_socket_path {
    my $self = shift;
    my (undef, $filename) = File::Temp::tempfile;
}

sub _build_socket {
    my $self = shift;
    my $socket = IO::Socket::UNIX->new(
        Local => $self->socket_path,
        Listen => 1);
    return $socket;
}

sub DEMOLISH {
    unlink $self->socket_path;
}

1;
