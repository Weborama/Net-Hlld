package Net::Hlld;

use strict;
use warnings;
use 5.010;
use Carp;
use autodie;
use utf8;

use constant CRLF => "\015\012";

use IO::Socket::INET;
use Digest::SHA;

use Net::Hlld::Exception::Network;
use Net::Hlld::Exception::Action;

use Moo;

our $VERSION = '0.001';

has 'socket' => (is => 'ro',
                 lazy => 1,
                 builder => '_build_socket');
has 'host' => (is => 'ro',
               default => q{localhost});
has 'port' => (is => 'ro',
               default => 4553);
has 'digester' => (is => 'ro',
                   lazy => 1,
                   builder => '_build_digester');
has 'digest_long_keys' => (is => 'ro',
                           predicate => 'should_digest_long_keys');

sub _build_socket {
    my $self = shift;
    my $socket = IO::Socket::INET->new(PeerHost => $self->host,
                                       PeerPort => $self->port,
                                       Proto => 'tcp');
    unless ($socket) {
        my $error = $@; # this looks and feels weird but the doc
        # actually says this
        Net::Hlld::Exception::Network->throw(message => $error);
    }
}

sub _build_digester {
    # SHA1 digests by default
    return Digest::SHA->new(1);
}

sub _digest_keys_maybe {
    my ($self, @keys) = @_;
    if ($self->should_digest_long_keys) {
        return map {
            length($_) > $self->digest_long_keys
                ? $self->digester->add($_)->b64digest
                : $_ } @keys;
    }
    return @keys;
}

sub send_command {
    my ($self, $command, @args) = @_;
    $self->socket->print(join(' ', $command, @args) . CRLF);

    my @answer;

    # the hlld protocol has only commands that either return a single
    # line (e.g. "Done") or multiple lines starting with "START" and
    # ending with "END" on their own lines.  Some commands can return
    # both.
    my $multiline_mode = 0;

    while (my $line = $self->socket->getline) {
        # not sure whether hlld returns CRLF or what.  this should
        # take care of all cases
        $line =~ s/\R$//;
        if ($line eq 'START') {
            # multi-line handling
            $multiline_mode = 1;
            next;
        }
        if ($line eq 'END') {
            last;
        }
        push @answer, $line;
        last unless $multiline_mode;
    }

    return @answer;

}

# List of commands in the current version:

# create - Create a new set (a set is a named HyperLogLog)
# list - List all sets or those matching a prefix
# drop - Drop a set (Deletes from disk)
# close - Closes a set (Unmaps from memory, but still accessible)
# clear - Clears a set from the lists (Removes memory, left on disk)
# set|s - Set an item in a set
# bulk|b - Set many items in a set at once
# info - Gets info about a set
# flush - Flushes all sets or just a specified one

sub hll_create {
    my ($self, $set_name, %options) = @_;
    my $die_if_exists_mode = 0;
    if (exists $options{die_if_exists}) {
        $die_if_exists_mode = $options{die_if_exists};
        delete $options{die_if_exists};
    }
    my ($answer) = $self->send_command(
        'create', $set_name,
        map { sprintf('%s=%s', $_, $options{$_}) } keys %options);
    if ($answer eq 'Done') {
        # all green
        return 1;
    } elsif ($answer eq 'Exists') {
        return 1 unless $die_if_exists_mode;
        Net::Hlld::Exception::Action->throw(action => 'create',
                                            message => 'Set already exists');
    } elsif ($answer eq 'Delete in progress') {
        Net::Hlld::Exception::Action->throw(action => 'create',
                                            message => $answer,
                                            temporary => 1);
    }
    Net::Hlld::Exception::Action->throw(action => 'create',
                                        message => $answer);
    return;
}

sub hll_list {
    my ($self, $optional_prefix) = @_;
    my @answer = $self->send_command('list', ($optional_prefix)x!!$optional_prefix);
    my %set_data;
    foreach my $set_short_info (@answer) {
        my ($set_name, $epsilon, $precision, $storage, $size) = split(/\s/, $set_short_info, 5);
        $set_data{$set_name} = { name => $set_name,
                                 epsilon => $epsilon,
                                 precision => $precision,
                                 storage => $storage,
                                 size => $size };
    }
    return %set_data;
}

sub hll_drop {
    my ($self, $set_name) = @_;
    my ($answer) = $self->send_command('drop', $set_name);
    if ($answer eq 'Done') {
        return 1;
    }
    Net::Hlld::Exception::Action->throw(action => 'drop',
                                        message => $answer);
    return;
}

sub hll_close {
    my ($self, $set_name) = @_;
    my ($answer) = $self->send_command('close', $set_name);
    if ($answer eq 'Done') {
        return 1;
    }
    Net::Hlld::Exception::Action->throw(action => 'close',
                                        message => $answer);
    return;
}

sub hll_clear {
    my ($self, $set_name) = @_;
    my ($answer) = $self->send_command('clear', $set_name);
    if ($answer eq 'Done') {
        return 1;
    } elsif ($answer eq 'Set is not proxied. Close it first.') {
        Net::Hlld::Exception::Action->throw(action => 'clear',
                                            message => $answer);
    }
    Net::Hlld::Exception::Action->throw(action => 'clear',
                                        message => $answer);
    return;
}

sub hll_set {
    my ($self, $set_name, $key) = @_;
    my ($answer) = $self->send_command('set', $set_name, $self->_digest_keys_maybe($key));
    if ($answer eq 'Done') {
        return 1;
    }
    Net::Hlld::Exception::Action->throw(action => 'set',
                                        message => $answer);
    return;
}

sub hll_bulk {
    my ($self, $set_name, @keys) = @_;
    my ($answer) = $self->send_command('bulk', $set_name, $self->_digest_keys_maybe(@keys));
    if ($answer eq 'Done') {
        return 1;
    }
    Net::Hlld::Exception::Action->throw(action => 'bulk',
                                        message => $answer);
    return;
}

sub hll_info {
    my ($self, $set_name) = @_;
    my @answer = $self->send_command('info', $set_name);
    if (@answer == 1) {
        # it's an error message, probably.
        Net::Hlld::Exception::Action->throw(action => 'info',
                                            message => $answer[0]);
    }
    return map { split(/\s+/, $_, 2)  } @answer;
}

sub hll_flush {
    my ($self, $optional_set_name) = @_;
    my ($answer) = $self->send_command('flush', ($optional_set_name)x!!$optional_set_name);
    if ($answer eq 'Done') {
        return 1;
    }
    Net::Hlld::Exception::Action->throw(action => 'flush',
                                        message => $answer);
    return;
}

1;
__END__
=pod

=head1 NAME

Net::Hlld -- Client for Armon Dadgar's HyperLogLog daemon

=head1 SYNOPSIS

  use Net::Hlld;
  
  # open connection to hlld
  my $client = Net::Hlld->new;
  
  # create a new set, setting some options
  $client->hll_create('foo', in_memory => 1);
  
  # create a new set, die if it already exists
  $client->hll_create('bar', die_if_exists => 1);
  
  # insert values on by one into the "foo" set
  $client->hll_set('foo', 'plugh');
  $client->hll_set('foo', 'xyzzy');
  
  # insert values in bulk
  $client->hll_bulk('bar', qw/a b c d e f g h i j k l m n o p q r s t u v w x y z/);
  
  # get the list of sets, and some associated data
  my %sets = $client->hll_list;
  
  foreach my $set_name (keys %sets) {
      my %set_info = %{$sets{$set_name}};
      say sprintf(q{Set '%s' has about %d values taking %d bytes of space; epsilon %d precision %d},
                  @set_info{qw/size storage epsilon precision/});
  }
  
  # get the list of sets starting with a given prefix
  my %purple_sets = $client->hll_list('purple-');
  
  # get extended info on a single set -- like hll_data, but returns a
  # single hash with keys in_memory, page_ins, page_outs, eps,
  # precision, sets, size, storage
  my %info = $client->hll_info('foo');
  
  # done with this set
  $client->hll_drop('foo');
  
  # done with that other set
  $client->hll_close('bar');
  $client->hll_clear('bar');

=head1 DESCRIPTION

L<Net::Hlld> is a thin client around the socket API of
L<hlld|https://github.com/armon/hlld>.  Due to the nature of the
protocol used, we can only guarantee that this module works with
C<hlld> version 0.5.4 which is the latest tag on the GitHub repo at
the time of writing.  Later versions of the daemon may remove or add
commands, or change the syntax of existing commands or responses.

=head1 ATTRIBUTES

=head2 digest_long_keys

(read-only integer)

If this attribute is set, then keys pushed via C<hll_set> or
C<hll_bulk> will be hashed client-side if they are longer than
C<digest_long_keys> characters, to minimize network traffic as
recommended by the hlld
L<README|https://github.com/armon/hlld/tree/master#clients>.

=head2 digester

(read-only lazy Digest object, defaults to a Digest::SHA object with
the SHA-1 algorithm selected)

Object implementing the Digest interface, to digest keys longer than
C<digest_long_keys> characters (assuming C<digest_long_keys> is set).

=head2 host

(read-only string, defaults to "localhost")

Machine hosting the hlld daemon.  This attribute is not used if
C<socket> is provided directly.

=head2 port

(read-only integer, defaults to 4553)

Port the hlld daemon is listening on.  Currently, hlld does not
support UNIX domain sockets.

=head2 socket

(read-only lazy IO::Socket instance)

This attribute is optional.  If it is not provided, C<host> and
C<port> will be used to build a new INET TCP socket.

=head1 METHODS

See the hlld
L<README|https://github.com/armon/hlld/tree/master#protocol> for the
official list of commands and their options.

The C<hll_*> methods are mostly straight up wrappers around the
corresponding commands, except that they throw exceptions for error
conditions instead of merely returning English messages, and they
return structured data where needed.

=head2 send_command

  my @lines = $client->send_command('command-name',
                                    $command_arg1,
                                    $command_arg2,
                                    ...);

Send an arbitrary command through the socket to the hlld instance.
The command name and arguments will be joined by a single space and
followed by a CRLF.

The return value is the list of lines (pre-chomped) returned by the
daemon.

All C<hll_*> methods are built around this method.

=head2 hll_create

  # create a new set, setting some options
  $client->hll_create('foo', in_memory => 1);

  # create a new set, die if it already exists
  $client->hll_create('bar', die_if_exists => 1);

The C<create> command initializes a new named set.  By default, it
does nothing if a set with the same name already exists; you can
however set the C<die_if_exists> parameter to have L<Net::Hlld> throw
an exception instead.  Other options are specified by hlld.

=head2 hll_list

  # get the list of sets, and some associated data
  my %sets = $client->hll_list;

  # get the list of sets starting with a given prefix
  my %purple_sets = $client->hll_list('purple-');

The C<list> command returns a short summary of data for all sets,
possibly filtered by prefix.

The server returns one line per set matched, which we parse to return
instead a hash of hashrefs keyed by set names:

  foo => {
    name => 'foo',
    size => approx. cardinality
    storage => size in bytes
    epsilon => maximum variance allowed
    precision => precision required, correlated to epsilon
  },
  bar => ...

The "name" key is an addition of L<Net::Hlld>, for easy iteration over
the values.

=head2 hll_drop

  # done with this set
  $client->hll_drop('foo');

Removes a set from disk.

=head2 hll_close

  # done with that other set
  $client->hll_close('bar');

Unmaps a set from memory.  The opposite operation is not documented;
it is unclear how to "reopen" a set.

Closed sets can be cleared with C<hll_clear>.

=head2 hll_clear

  # SO done with that other set, I don't even
  $client->hll_clear('bar');

Clears memory for a set.  The set needs to be closed with C<hll_close>
first.

=head2 hll_set

  # insert values on by one into the "foo" set
  $client->hll_set('foo', 'plugh');
  $client->hll_set('foo', 'xyzzy');

Insert a single value into a set.

=head2 hll_bulk

  # insert values in bulk
  $client->hll_bulk('bar', qw/a b c d e f g h i j k l m n o p q r s t u v w x y z/);

Insert multiple values into a set.

=head2 hll_info

  my %info = $client->hll_info('foo');

Returns a hash of statistics for a single set.

  in_memory => 1,
  page_ins => 0,
  page_outs => 0,
  eps => 0.02,
  precision => 12,
  sets => 0,
  size => 1540,
  storage => 3280

=head2 hll_flush

  # flush a single set
  $client->flush('foo');

  # flush all sets
  $client->flush;

Flush a single set, or all sets, to disk.

=head1 EXCEPTIONS THROWN

Exceptions thrown are instances of subclasses of L<Throwable::Error>
(unless of course we did not throw them ourselves in which case all
bets are off).

Please refer to L<Net::Hlld::Exception::Action> and
L<Net::Hlld::Exception::Network>.

=head1 SEE ALSO

The daemon implementation on
L<GitHub|https://github.com/armon/hlld/tree/master> by Armon Dadgar.

L<Throwable::Error>.

=head1 AUTHOR

Fabrice Gabolde <fgabolde@weborama.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 Weborama.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or (at
your option) any later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA
02110-1301 USA.

=cut
