package Exchange::Bitfinex;
use strict;
use warnings;

use parent 'Exchange';
use JSON::XS qw{decode_json encode_json};

use Data::Dumper;
use Try::Tiny;

sub _init {
  my $self = shift;
  $self->{channels} = {}; # store ws channel for each currency
  $self->{config} = {
	    'id' => 'bitfinex',
            'name' => 'Bitfinex v.2',
            'countries' => 'US', 
            'rateLimit' => 500,
            'base_currency' => 'USD',
            'has' => {
                'CORS' => 1,
                'fetchTickers' => 1,
                'withdraw' => 1,
            },
        'urls' => {
                'logo' => 'https://user-images.githubusercontent.com/1294454/27766244-e328a50c-5ed2-11e7-947b-041416579bb3.jpg',
                'api' => 'https://api.bitfinex.com',
                'www' => 'https://www.bitfinex.com',
                'doc' => {
                    'https://bitfinex.readme.io/v1/docs',
                    'https://github.com/bitfinexcom/bitfinex-api-node',
                },
            },
            'can' => {
            	'rest'  => 1,
            	'push'  => 0,
            	'wsock' => 0, #disabled. wrong data stored, check highest bid /lowest ask compared to rest ticker results
            },
            'fees' => {
                'trading' => {
                    'maker' => 0.15 / 100,
                    'taker' => 0.15 / 100,
                },
            },
        'symbols' => $self->_get_symbols()
    },
}

sub ticker {
  my $self = shift;
  my %vars = @_;

  my @symbols = @{$self->{config}->{symbols}};
  map $_ = 't'  . uc $_->{id}, grep {$self->symbol_allowed($_->{id}) || $self->symbol_allowed('t'.$_->{id})} @symbols; # convert to their format i.e. tBTCUSD
  my $symbol_string = join ',', @symbols;
  
  $self->get(
    url => "https://api.bitfinex.com/v2/tickers?symbols=$symbol_string",
    on_result => sub { $self->process_ticker(@_) },
    on_error  => sub { $self->common_error(@_) },
  );

}

sub ticker_ws {
  my $self = shift;
  my %vars = @_;
  
  my $symbol = 't'  . uc $vars{symbol};
  #warn "Subscribed to ".$vars{symbol};

  $self->subscribe(
    url => 'wss://api.bitfinex.com/ws/2',
    request => qq[{
      "event": "subscribe",
      "channel": "ticker",
      "symbol": "$symbol"
    }],
    on_result => sub { $self->process_ticker(@_) },
    on_error  => sub { $self->common_error(@_) },
  );
}

sub process_ticker { 
  my $self = shift;
  my $tx = shift;

  my $ws_data = shift || undef;
   
  my $res  = $tx->result->json;
  
  my $currencies;
  my $ws_currency = '';
  if(defined $ws_data) {#print Dumper $ws_data;
    #message can be
    # [82,"hb"] - SKIP
    # {"event":"info","version":2} - SKIP
    # [80,[0.00001134,576365.65645501,0.00001146,268083.27502921,-3.9e-7,-0.0039,0.00001134,1724252.96570323,0.0000122,0.00001037]] - PROCESS

    $currencies = decode_json $ws_data;
    if ('ARRAY' eq ref $currencies && @{$currencies}[1] ne "hb") {
      if('ARRAY' eq ref @{$currencies}[1]) {
        my $channel_id = @$currencies[0]; 
        $currencies = @{$currencies}[1];
        $ws_currency = $self->{channels}->{$channel_id}; 
      }
    }
    elsif ('HASH' eq ref $currencies) # get channel id
    {
      if (defined $currencies->{channel} && defined $currencies->{chanId})
      {
        my $stored_channed_id = $currencies->{chanId}; # save for future
        $self->{channels}->{$stored_channed_id} = $currencies->{symbol};
      }
       return;
    }
    else {
      $self->logger->info("No params returned by bitfinex");
      return undef;
    }
  }
  else {
    $currencies = $res;
  }
  
  my @data;
  if(defined $ws_data) {
    push @data, $currencies;
  } elsif ($currencies && 'ARRAY' eq ref $currencies) {
    @data = @{$currencies};
  } else {
    $self->common_error("No data in the ticker response", vars => 1, response => $currencies);
    return;
  }

  foreach my $currency (@data) {
    if(!defined $ws_data) {
        $ws_currency=@$currency[0];
    }
  #  SYMBOL, -- in REST API only
  #  [BID, 
  #  BID_SIZE, 
  #  ASK, 
  #  ASK_SIZE, 
  #  DAILY_CHANGE, 
  #  DAILY_CHANGE_PERC, 
  #  LAST_PRICE, 
  #  VOLUME, 
  #  HIGH, 
  #  LOW]
  $self->store_ticker(
      source		=> $self->config->{id},
      currency		=> $ws_currency,
      status		=> 0, # proper status for the ticker w/o errors
      date_ts		=> time,
      base_currency 	=> $self->config->{base_currency},
      base_usd_rate	=> $self->usd_rates->{$self->config->{base_currency}}//1,
      highest_bid	=> @$currency[1],
      lowest_ask	=> @$currency[3],
      opening_price	=> 0,
      closing_price	=> 0, 
      min_price		=> @$currency[10],
      max_price		=> @$currency[9],
      average_price	=> 0,
      units_traded	=> 0,
      volume_1day	=> 0,
      volume_7day	=> 0, 
    );

  }
  return 1;
}


sub _get_symbols {
  my $self = shift;
  my $result =  decode_json $self->ua->get('https://api.bitfinex.com/v1/symbols')->result->body; # note that API v.2 doesn't have this functionality, can be removed later!
  my $new_result;
  
  foreach (@$result) { # should be always named 'id' for using in loops
    next unless $self->symbol_allowed($_) || $self->symbol_allowed('t'.$_);
    push @{$new_result}, {id => $_};
  }
  
  return $new_result;
}

2;
