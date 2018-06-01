package Exchange::HitBtc;
use strict;
use warnings;

use parent 'Exchange';
use JSON::XS qw{decode_json encode_json};

use Data::Dumper;
use Try::Tiny;

sub _init {
  my $self = shift;
  $self->SUPER::_init(@_);
  $self->{config} = {
	    'id' => 'hitbtc',
            'name' => 'HitBTC',
            'countries' => 'KR', 
            'rateLimit' => 500,
            'base_currency' => 'USD',
            'has' => {
                'CORS' => 1,
                'fetchTickers' => 1,
                'withdraw' => 1,
            },
            'urls' => {
                'logo' => 'https://api.hitbtc.com/images/logo.png',
                'api' => {
                    'public' => 'https://api.hitbtc.com/api/2/public',
                    'private' => 'https://api.hitbtc.com/api/2',
                },
                'www' => 'https://hitbtc.com',
                'doc' => 'https://hitbtc.com',
            },
            'can' => {
            	'rest'  => 1,
            	'push'  => undef,
            	'wsock' => {
            	  'ticker' => undef
            	},
            },
            'fees' => {
                'trading' => {
                    'maker' => 0.15 / 100,
                    'taker' => 0.15 / 100,
                },
            },
            'symbols' => decode_json $self->ua->get('https://api.hitbtc.com/api/2/public/symbol')->result->body
    },
        
}

sub ticker {
  my $self = shift;
  my %vars = @_;

  $self->get(
    url => 'https://api.hitbtc.com/api/2/public/ticker',
    on_result => sub { $self->process_ticker(@_) },
    on_error  => sub { $self->common_error(@_) },
  );
}

sub ticker_ws {
  my $self = shift;
  my %vars = @_;
  
  my $symbol = $vars{symbol};
  return unless $self->symbol_allowed($symbol);
  #warn "Subscribed to ".$vars{symbol};
  $self->subscribe(
    url => 'wss://api.hitbtc.com/api/2/ws',
    request => qq[{
     "method": "subscribeTicker",
     "params": {
        "symbol": "$symbol"
     },
     "id": 123
    }],
    on_result => sub { $self->process_ticker(@_) },
    on_error  => sub { $self->common_error(@_, vars => { method => 'ws', symbol => $symbol }) },
  );
}


sub process_ticker {
  my $self = shift;
  my $tx = shift;
  my $ws_data = shift || undef;
  
  my $res   	= $tx->result->json;
  #print Dumper $ws_data;

  my $stat_date = time;
  my $currencies;
  if(defined $ws_data) {
    $currencies = decode_json $ws_data;
    if ('HASH' eq ref $currencies && $currencies->{method} && $currencies->{method} eq 'ticker' && $currencies->{params} && 'HASH' eq ref $currencies->{params}) {
      $currencies = [$currencies->{params}];
    } else {
      #$self->logger->info("No params returned by hitbtc");
      return undef;
    }
  }
  else {
    $currencies = $res;
  }
  
  #warn "Store...".Dumper($currencies);

  foreach my $currency (@$currencies) {
    #print Dumper $currency;
    $self->store_ticker(
      source		=> $self->config->{id},
      currency		=> $currency->{symbol},
      status		=> 0, # proper status for the ticker w/o errors
      date_ts		=> time, #$currency->{timestamp}, # it should be the timestamp
      base_currency 	=> $self->config->{base_currency},
      base_usd_rate	=> $self->usd_rates->{$self->config->{base_currency}}//1,
      highest_bid	=> $currency->{bid},
      lowest_ask	=> $currency->{ask},
      opening_price	=> $currency->{open},
      closing_price	=> $currency->{last}, 
      min_price		=> $currency->{low},
      max_price		=> $currency->{high},
      average_price	=> 0, #maybe can be calculated manually if not present?
      units_traded	=> 0,
      volume_1day	=> $currency->{volumeQuote},
      volume_7day	=> 0, 
    );
  }

  return 1;
}
















2;


