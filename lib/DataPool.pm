package DataPool;
use strict;
use warnings;

use Mojo::Base -strict;
use Mojo::mysql;

use Data::Dumper;
use POSIX qw(strftime);
use Try::Tiny;
use JSON::XS qw{decode_json encode_json};



sub new {
  my $pkg  = shift;
  my %args = (
    dryrun  => undef, # do not either store or post 
    dbh     => undef, # expects Mojo::mysql object 
    logger  => undef, # expects logger
    store_empty => 1,
    table   => undef,
    bootstrap => undef,
    @_ 
  );

  my $self =  bless(
    {%args}, $pkg
  );

  $self->_init;

  return $self;
}

sub _init {
  my $self = shift;
  $self->reset_all;
}

sub dbh {
  return $_[0]->{dbh}->db;
}

sub table {
  return $_[1] ? $_[0]->{table} = $_[1] : $_[0]->{table};
}

sub pool {
  return defined $_[1] ? $_[0]->{pool} = $_[1] : $_[0]->{pool};
}

sub bootstrap {
  return $_[0]->{bootstrap};
}

sub store_empty {
  return $_[1] ? $_[0]->{store_empty} = $_[1] : $_[0]->{store_empty};
}

sub reset_all {
  my $self = shift;
  $self->pool({});
  $self->{update_flags} = {};
}

sub count {
  return scalar keys %{$_[0]->pool};
}

sub set {
  my $self = shift;
  my %vars = @_;
  $self->pool->{$vars{key}} = $vars{value};
  $self->{update_flags}->{$vars{key}} = time;
}



sub get {
  my $self = shift;
  my %vars = @_;
  return $self->pool->{$vars{key}};
}

sub store {
  my $self = shift;
  my %vars = @_;

  foreach my $k (keys %{$self->pool}) {
    next if $self->key_blacklisted($k);
    $self->dbh->query("insert into `".$self->config->{table}."` values (null,??)", @{$self->pool->{$k}}) if $self->pool->{$k};
    delete $self->{update_flags}->{$k};
  }
}

sub updated_count {
  return scalar keys %{$_[0]->{update_flags}};
}

sub keys_whitelist {
  return $_[1] ? $_[0]->{keys_whitelist} = $_[1] : $_[0]->{keys_whitelist}; # expects hash!
}

sub key_whitelisted {
  my $self = shift;
  return 1 if $self->bootstrap;
  return undef unless $self->keys_whitelist && 'HASH' eq ref $self->keys_whitelist && $self->keys_whitelist->{$_[0]};
  return 1;
}

sub keys_blacklist {
  my $self = shift;
  return $_[1] ? $_[0]->{keys_blacklist} = $_[1] : $_[0]->{keys_blacklist}; # expects hash!
}

sub key_blacklisted {
  my $self = shift;
  return 1 if $self->keys_whitelist &&! $self->key_whitelisted($_[0]);
  return undef if $self->keys_whitelist && $self->key_whitelisted($_[0]);
  return 1 if $self->keys_blacklist && 'HASH' eq ref $self->keys_blacklist && $self->keys_blacklist->{$_[0]};
  return undef;
}

sub __dump_keys {
  my $self = shift;
}

1;