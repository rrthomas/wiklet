# RRT::Wiki (c) 2003 Reuben Thomas (rrt@sc3d.org; http://rrt.sc3d.org)
# Distributed under the GNU General Public License

# Provide a Wiki class (storing multiple versions of pages in a
# database)

require 5.003;
package RRT::Wiki;

use strict;
use warnings;

use GDBM_File;


# Create a Wiki object, or open an existing one
sub new {
  my ($class, $file) = @_;
  my %db;
  tie %db, "GDBM_File", $file, &GDBM_WRCREAT;
  my $self = bless %db, $class;
}

sub destroy {
  my ($self) = @_;
  untie $self;
}

sub add {
  my ($self, $page, $text) = @_;
  ${$self}{$page} = {} if undef ${$self}{$page};
  ${$self}{$page}->{VERSION} = 0 if undef ${$self}{$page}->{VERSION};
  my $version = ++${$self}{$page}->{VERSION};
  ${$self}{"$version|$page"} = $text;
  ${$self}{$page}->{TIME} = time;
}

sub get {
  my ($self, $page, $version) = @_;
  return undef if !defined($self->exists($page));
  $version = $self->current($page) if !defined($version);
  my $text = ${$self}{"$version|$page"};
  return $text;
}

sub delete {
  my ($self, $page);
  for (my $i = 0; $i <= ${$self}{page}->{VERSION}; $i++) {
    undef ${$self}{"$i|$page"};
  }
  undef ${$self}{$page};
}

sub exists {
  my ($self, $page) = @_;
  return defined(${$self}{$page});
}

sub current {
  my ($self, $page) = @_;
  return ${$self}{$page}->{VERSION}; # versions are numbered from 1
}

sub lastModified {
  my ($self, $page);
  return ${$self}{$page}->{TIME};
}

sub lock {
  my ($self, $page);
  ${$self}{$page}->{LOCKED} = 1;
}

sub unlock {
  my ($self, $page);
  undef ${$self}{$page}->{LOCKED};
}

sub locked {
  my ($self, $page);
  return ${$self}{$page}->{LOCKED};
}
