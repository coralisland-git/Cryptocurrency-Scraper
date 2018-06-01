package Exchange::Huobi;
use strict;
use warnings;

use parent 'Exchange';
use JSON::XS qw{decode_json encode_json};

use Data::Dumper;
use Try::Tiny;
use Time::Piece;
use IO::Uncompress::Gunzip qw(gunzip $GunzipError) ;

sub _init {
  my $self = shift;
  $self->{channels} = {}; # store ws channel for each currency
  $self->{config} = {
	    'id' => 'huobi',
            'name' => 'Huobi',
            'countries' => 'CN', 
            'rateLimit' => 500,
            'base_currency' => 'CNY',
            'has' => {
                'CORS' => 1,
                'fetchTickers' => 1,
                'withdraw' => 1,
            },
        'urls' => {
                'logo' => 'https://user-images.githubusercontent.com/1294454/27766569-15aa7b9a-5edd-11e7-9e7f-44791f4ee49c.jpg',
                'api' => 'api.huobi.pro', # don't change, don't add `http` etc! used to generate signature
                'www' => 'https://www.huobi.com',
                'doc' => 'https://github.com/huobiapi/API_Docs_en/wiki',
            },
            'can' => {
            	'rest'  => 1,
            	'push'  => 0,
            	'wsock' => 1,
            },
            'fees' => {
                'trading' => {
                    'maker' => 0.0,
                    'taker' => 0.25 / 100,
                },
            },

        'symbols' => $self->_get_symbols()
    },
}

sub ticker {
  my $self = shift;
  my %vars = @_;

  foreach my $symbol (@{$self->{config}->{symbols}}) {
    $self->get(
      url => "https://api.huobi.pro/market/detail/merged?symbol=$symbol->{id}",
      on_result => sub { $self->process_ticker(@_, undef, id => $symbol->{id}) },
      on_error  => sub { $self->common_error(@_) },
    );
  }

}

sub ticker_ws {
  my $self = shift;
  my %vars = @_;
  
  my $time = time();
  my $symbol = $vars{symbol};
  my $id = "id{$symbol}_$time";
  my $request = {
    "req" => "market.$symbol.detail",
    "id" => $id
  };
  
  $self->{channels}->{$id} = $symbol;
  
  $self->subscribe(
    url => 'wss://api.huobi.pro/ws',
    request => encode_json $request,
    on_result => sub { $self->process_ticker(@_, id => 0) },
    on_error  => sub { $self->common_error(@_) },
  );
}

sub process_ticker {
  my $self = shift;
  my $tx = shift;
  my $ws_data = shift || undef;

  my %vars = @_;
  if ($ws_data !~ m/\A [[:ascii:]]* \Z/xms) {# data is a binary
    my $buffer;
    gunzip \$ws_data => \$buffer;
    $ws_data = $buffer;
    print  "\n" . $ws_data . "\n";
  }

  my $currency;
  my $ws_currency = '';
  my $time_stamp;
  if(defined $ws_data) {
    $ws_data = decode_json $ws_data;
    return if defined $ws_data->{ping};
    $currency = $ws_data->{data};
    $time_stamp = time();
    my $id = $ws_data->{id};
    $vars{id} = $self->{channels}->{$id};
  }
  else {
    $currency = $tx->result->json->{tick};

    $time_stamp = substr($tx->result->json->{ts},0, -3); #remove mseconds
  }
  
  

  $self->store_ticker(
      source		=> $self->config->{id},
      currency		=> $vars{id},
      status		=> 0, # proper status for the ticker w/o errors
      date_ts		=> $time_stamp,
      base_currency 	=> $self->config->{base_currency},
      base_usd_rate	=> $self->usd_rates->{$self->config->{base_currency}}//1,
      highest_bid	=> $currency->{high},
      lowest_ask	=> $currency->{low},
      opening_price	=> $currency->{open},
      closing_price	=> $currency->{close}, 
      min_price		=> 0,
      max_price		=> $currency->{price},
      average_price	=> 0,
      units_traded	=> $currency->{count},
      volume_1day	=> 0,
      volume_7day	=> 0, 
    );
  
  return 1;
}


sub common_error {
  my $self = shift;
  $self->logger->info($_[0]);
}


sub _get_symbols {
  my $self = shift;
  my $result = decode_json $self->ua->get('https://api.huobi.pro/v1/common/symbols')->result->body;
  $result = $result->{data};  
  map {$_->{id} = $_->{'base-currency'}.$_->{'quote-currency'}} @$result; # should be always named 'id' for using in loops

  return $result;
}


1;
