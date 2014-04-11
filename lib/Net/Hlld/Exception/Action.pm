package Net::Hlld::Exception::Action;

use strict;
use warnings;
use 5.010;
use Carp;
use autodie;
use utf8;

use Moo;
extends 'Net::Hlld::Exception';

has 'action' => (is => 'ro',
                 required => 1);
has 'temporary' => (is => 'ro',
                    default => 0);

1;
__END__
=pod

=head1 NAME

Net::Hlld::Exception::Action -- Class for Net::Hlld exceptions related to user actions

=head1 SYNOPSIS

  eval { $client->create('foo') };
  if (my $exception = $@) {
      if (blessed $exception
          and $exception->isa('Net::Hlld::Exception::Action')) {
          if ($exception->temporary) {
              # retry the set creation
          }
          # not temporary, so probably nothing we can do about it
          $exception->rethrow;
      } else {
          # ...
      }
  }

=head1 DESCRIPTION

This is a L<Throwable::Error>-derived exception class for L<Net::Hlld>
exceptions.  It is a subclass of L<Net::Hlld::Exception>.

Instances of this class are intended to be created and thrown when a
command sent to the hlld daemon cannot be completed successfully on
the daemon, e.g. dropping a set that does not exist.  Because most
hlld commands return English strings it is difficult to tell
automatically when a command failed, and so C<hll_*> methods try to
detect when a failure message was returned and turn it into an
exception.

=head1 ATTRIBUTES

=head2 action

The command that returned in failure.

=head2 temporary

Whether the failure was temporary and the command can be re-sent with
the same parameters after a suitable amount of time.

Currently this attribute only has a true value in the specific case of
trying to create a set that has been very recently deleted.

=head1 METHODS

No new methods.

=head1 SEE ALSO

L<Net::Hlld>

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
