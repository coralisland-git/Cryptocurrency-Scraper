package Exchange;
use strict;
use warnings;


use Mojo::Base -strict;
use Mojo::IOLoop;
use Mojo::UserAgent;
use Mojo::mysql;

use Data::Dumper;
use POSIX qw(strftime);
use Time::HiRes qw(gettimeofday tv_interval);
use Try::Tiny;
use JSON::XS qw{decode_json encode_json};
use DateTime::Format::Strptime qw(strptime);
use POSIX qw( strftime );
use DateTime;
use IO::Uncompress::Unzip qw(unzip $UnzipError);
use IO::Uncompress::Gunzip qw(gunzip $GunzipError) ;

sub new {
  my $pkg  = shift;
  my %args = (
    dryrun  => undef, # do not either store or post 
    dbh     => undef, # expects Mojo::mysql object 
    ua	    => undef, # expects Mojo::UserAgent
    logger  => undef, # expects logger
    pool    => undef,
    usd_rates => undef, #expects reference to usd rates hash
    config  => {
	    'id' => undef,
            'name' => undef,
            'countries' => undef,
            'rateLimit' => undef,
            'has' => {
                'CORS' => undef,
                'fetchTickers' => undef,
                'withdraw' => undef,
            },
            'can' => {
            	'rest'  => undef,
            	'push'  => undef,
            	'wsock' => undef,
            },
            'urls' => {
                'logo' => undef,
                'api' => {
                    'public' => undef,
                    'private' => undef,
                },
                'www' => undef,
                'doc' => undef,
            },            
            'fees' => {
                'trading' => {
                    'maker' => undef,
                    'taker' => undef,
                },
            },
            'symbols' => {
            },
    },
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
  $self->{status_vars} = {
    ws_ticker_subscriptions => 0,
  };
}

################################################




sub config {
  return $_[0]->{config};
}

sub dbh {
  return $_[0]->{dbh};
}

sub ua {
  return $_[0]->{ua};
}

sub logger {
  return $_[0]->{logger};
}

sub pool {
  return $_[0]->{pool};
}

sub usd_rates {
  return $_[0]->{usd_rates};
}

sub can_wsock {
  return $_[0]->config->{can}->{wsock} ? (
    $_[1] && 'HASH' eq ref $_[0]->config->{can}->{wsock} ? $_[0]->config->{can}->{wsock}->{$_[1]} : 1
  ) : undef;
}

sub can_rest {
  return $_[0]->config->{can}->{rest};
}

sub can_push {
  return $_[0]->config->{can}->{push};
}

sub can_ping {
  return $_[0]->config->{can}->{ping};
}

sub debug {
  return $_[0]->{debug};
}

sub symbols_filter {
  return $_[0]->{symbols_filter}; # expects hash
}

sub symbol_allowed {
  return undef if 'HASH' eq ref $_[0]->symbols_filter && !$_[0]->symbols_filter->{$_[1]};
  return 1;
}

sub api {
  my $self = shift;
  my $type = $_[0]//'public';
  my $api = $self->config->{urls}->{api};
  if ($api && 'HASH' eq ref $api && $api->{$type}) {
    return $api->{$type}
  } elsif ($api) {
    return $api;
  } else {
    die "Wrong api url definition";
  }
}

sub method {
  my $self = shift;
  my ($type, $endpoint) = @_;  

  if ('HASH' eq ref $self->config->{apis} && $self->config->{apis}->{$type} && 'HASH' eq ref $self->config->{apis}->{$type} && $self->config->{apis}->{$type}->{$endpoint}) {
    return $self->config->{apis}->{$type}->{$endpoint}->{method};
  } else {
    return undef;
  }
}

sub get {
  my $self = shift;
  my %vars = (
    url      => undef,
    vars     => {},
    headers => {},
    raw_content => undef,
    on_result => undef,
    on_error => undef,
    no_throttle => undef,
    @_
  );

  $self->async_throttle($vars{no_throttle}, sub{
    my $url = $vars{url}.($vars{raw_content}?'?'.$vars{raw_content}:'');

    #die $url;

    return $self->ua->get_p($url => $vars{headers} => form => $vars{vars})->then(sub {
      $vars{on_result}(@_) if $vars{on_result};
    })->catch(sub {
      $vars{on_error}(@_) if $vars{on_error};
    });
  });
}

sub post {
  my $self = shift;
  my %vars = (
    url      => undef,
    vars     => {},
    headers => {},
    raw_content => undef,
    on_result => undef,
    on_error => undef,
    no_throttle => undef,
    @_
  );

  #warn Dumper \%vars;
  #die Dumper ($vars{url} => $vars{headers} => ($vars{raw_content} ? $vars{raw_content} : form => $vars{vars}));
  $self->async_throttle($vars{no_throttle}, sub{
    return $self->ua->post_p($vars{url} => $vars{headers} => $vars{raw_content} ? $vars{raw_content} : form => $vars{vars})->then(sub {
      $vars{on_result}(@_) if $vars{on_result};
    })->catch(sub {
      $vars{on_error}(@_) if $vars{on_error};
    });
  });
}

sub put {
  my $self = shift;
  my %vars = (
    url      => undef,
    vars     => {},
    headers => {},
    raw_content => undef,
    on_result => undef,
    on_error => undef,
    no_throttle => undef,
    @_
  );

  #warn Dumper \%vars;
  #die Dumper ($vars{url} => $vars{headers} => ($vars{raw_content} ? $vars{raw_content} : form => $vars{vars}));
  $self->async_throttle($vars{no_throttle}, sub{
    return $self->ua->put_p($vars{url} => $vars{headers} => $vars{raw_content})->then(sub {
      $vars{on_result}(@_) if $vars{on_result};
    })->catch(sub {
      $vars{on_error}(@_) if $vars{on_error};
    });
  });
}


sub delete {
  my $self = shift;
  my %vars = (
    url      => undef,
    vars     => {},
    headers => {},
    raw_content => undef,
    on_result => undef,
    on_error => undef,
    no_throttle => undef,
    @_
  );

  #warn Dumper \%vars;
  #die Dumper ($vars{url} => $vars{headers} => ($vars{raw_content} ? $vars{raw_content} : form => $vars{vars}));
  $self->async_throttle($vars{no_throttle}, sub{
    return $self->ua->delete_p($vars{url} => $vars{headers} => $vars{raw_content})->then(sub {
      $vars{on_result}(@_) if $vars{on_result};
    })->catch(sub {
      $vars{on_error}(@_) if $vars{on_error};
    });
  });
}

sub subscribe {
  my $self = shift;
  # handle web socket connection there
  my %vars = (
    channel   => undef,
    url       => undef,
    vars      => undef,
    request   => undef,
    on_result => undef,
    on_error  => undef,
    reconnect_on_finish => undef,
    ping      => {
      enabled  => undef,
      interval => 30, # seconds
      on_ping  => sub { my $tx = shift; },
    },	
    #on_unexpected
    # etc
    # read Mojo::Transaction::HTTP manual
    @_
  );

  $self->{status_vars}->{ws_ticker_subscriptions}++;
  return $self->ua->websocket_p($vars{url})->then(sub {
    my $tx = shift;
    my $promise = Mojo::Promise->new;
    my $ping_id;
    $tx->on(finish => sub { 
      $promise->resolve; 
      if ($ping_id) {
        Mojo::IOLoop->singleton->remove($ping_id);
      }

      $self->{status_vars}->{ws_ticker_subscriptions}--; 

      if ($vars{reconnect_on_finish}) {
        $self->subscribe(%vars);
      }
    });
    $tx->on(message => sub {
      my ($tx, $msg) = @_;
      if ($msg !~ m/\A [[:ascii:]]* \Z/xms) {# data is a binary
        my $buffer;
        gunzip \$msg => \$buffer;
        $msg = $buffer;
      }
      say "WebSocket message: $msg" if $ENV{DEBUG_WS};
      my $result = decode_json $msg;
      if ('HASHREF' eq ref $result) { # Bitfinex outputs data as array so we need to check type
        return if defined $result->{result} ; # SKIP on WebSocket message: {"jsonrpc":"2.0","result":true,"id":123}
      }
      #say "On result" if $vars{on_result};;
      $vars{on_result}(@_) if $vars{on_result};
    });

    if ($vars{ping} && $vars{ping}->{enabled}) {
      $ping_id = Mojo::IOLoop->singleton->recurring($vars{ping}->{interval} => sub {
        my $loop = shift;
        $vars{ping}->{on_ping}($tx);
      });
    }

    $tx->send($vars{request});   
    return $promise;
  })->catch(sub {
    $vars{on_error}(@_) if $vars{on_error};
    #$self->common_error( "WebSocket error - $err" );
  });  
}

sub ws_ticker_subscriptions {
  my $self = shift;
  return $self->{status_vars}->{ws_ticker_subscriptions};
}

sub process {
}


sub store_ticker {
  my $self = shift;
  my %vars = @_;

  $self->pool->set(
    key => join('-', $vars{source}, $vars{currency}),
    value => [
      $vars{source}, $vars{base_currency}, $vars{base_usd_rate}, $vars{currency}, $vars{status}, 
      $vars{date_ts}, $vars{date_ts}, $vars{date_ts},
      $vars{highest_bid}, $vars{lowest_ask}, $vars{opening_price}, $vars{closing_price},
      $vars{min_price}, $vars{max_price}, $vars{average_price}, $vars{units_traded},
      $vars{volume_1day}, $vars{volume_7day},
    ]
  );
}




sub common_error {
  my $self = shift;
  my $error = shift;
  my %vars = @_ if @_;
  $self->logger->info(($self->config->{id}//"Unknown").": ".$error);
  if ($self->debug && $vars{vars}) {
    $self->logger->info(Dumper \%vars);
  }
}



######################################
sub str2ts {
  my $self = shift;
  my $str = shift;
  
  my $obj; 
  
  $str=~s/Z$//is;

  if ($str =~/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d+$/) {
    $obj = strptime('%FT%T.%N', $str);
  } elsif ($str =~/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}$/) {
    $obj = strptime('%FT%T', $str);
  } elsif ($str =~/^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}$/) {
    $obj = strptime('%F %T', $str);
  }

  if ($obj) {
    return $obj->epoch;
  } 

  $self->common_error("Wrong timestamp format: ".$str);
  return undef;
}

sub ts2str {
  my $self = shift;
  my $ts = shift;
  my $dt = strftime("%Y-%m-%d %H:%M:%S", gmtime($ts));
  return $dt;
}

sub iso8601 {
  my $self = shift;
  my $ts = shift;
  return DateTime->from_epoch(epoch => $ts)->iso8601;
}

sub tsns2str {
  my $self = shift;
  return $self->ts2str($_[0]/1000000);
}

sub next_throttled_in {
  my $self = shift;
     $self->{throttle_counter}//=0;
     $self->{throttle_starttime}//=[gettimeofday];
     $self->{throttle_counter}++;

  return 0 if ($self->{throttle_counter} == 1);

  my $t_elapsed =  tv_interval($self->{throttle_starttime});
  my $next = ( ($self->{throttle_counter} - 1) * ($self->config->{rateLimit}/1000) ) - $t_elapsed;
  if ($next > 0) {
    return sprintf('%.3f', $next);
  } else {
    $self->{throttle_counter} = 1;
    $self->{throttle_starttime}=[gettimeofday];
    return 0;
  }
}

sub async_throttle {
  my $self = shift;
  my $no_throttle = shift; # disble throttling
  my $sub  = shift; # anonymous subroutine

  if ($no_throttle || !$self->config->{rateLimit}) {
    warn "not throttled :)" if $ENV{DEBUG_THROTTLE};
    return Mojo::IOLoop->singleton->next_tick($sub);
  }

  my $next = $self->next_throttled_in;
  warn "next throttled in $next seconds" if $ENV{DEBUG_THROTTLE};
  return Mojo::IOLoop->singleton->timer($next => $sub);
}




1;