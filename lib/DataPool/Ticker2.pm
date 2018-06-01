package DataPool::Ticker2;
use strict;
use warnings;

use parent 'DataPool';

use Data::Dumper;
use Try::Tiny;

sub _init {
  my $self = shift;
  $self->SUPER::_init(@_);
  $self->table('ticker2');
}

sub store {
  my $self = shift;
  my %vars = @_;

  #warn "Store pool";
  #warn Dumper $self->pool;

  foreach my $k (keys %{$self->pool}) {
    next unless $self->pool->{$k};
    next if $self->key_blacklisted($k) && !$vars{bootstrap};

    $self->dbh->query(
      "insert into `".$self->table."` values (NULL, now(), ?, ?, ?, ?, ?, from_unixtime(round(?)), round((?-?%60)/60,0), ?, ?, ?, ?,  ?, ?, ?, ?,  ?, ?)", 
      @{$self->pool->{$k}}
    );

    delete $self->{update_flags}->{$k};
  }
}



















2;