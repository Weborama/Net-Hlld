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
