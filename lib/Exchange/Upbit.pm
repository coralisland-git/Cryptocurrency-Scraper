package Exchange::Upbit;
use strict;
use warnings;

use parent 'Exchange';

use Data::Dumper;
use Try::Tiny;

sub _init {
  my $self = shift;
  $self->{config} = {
	    'id' => 'upbit',
            'name' => 'Upbit',
            'countries' => 'KR', 
            'rateLimit' => 500, # no info
            'base_currency' => 'KRW',
            'has' => {
                'CORS' => 1,
                'fetchTickers' => 1,
                'withdraw' => 1,
            },
            'urls' => {
                'logo' => 'https://cdn.upbit.com/images/bg.2680af0.png',
                'api' => 'https://crix-api-endpoint.upbit.com/v1/',
                'www' => 'https://upbit.com/',
                'doc' => 'https://steemkr.com/kr/@segyepark/api',
            },
            'can' => {
            	'rest'  => 1,
            	'push'  => undef,
            	'wsock' => undef,
            },
            'fees' => {
                'trading' => {
                    'maker' => 0.25 / 100,
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
    next if !defined $symbol->{id};

    $self->get(
      url => "https://crix-api-endpoint.upbit.com/v1/crix/candles/minutes/240?code=CRIX.UPBIT.$symbol->{id}",
      on_result => sub { $self->process_ticker(@_, undef, id => $symbol->{id}) },
      on_error  => sub { $self->common_error(@_) },
    );
  }

}

sub process_ticker {
  my $self = shift;
  my $tx = shift;
  my ($tp1, $tp2, $curr) = (@_);

  my $res   	= $tx->result->json;

  if (! defined $res || (ref($res) eq 'HASH' && $res->{status} == 404)){
    return 1;
  }

  my $currency = delete $res->[0];

  $self->store_ticker(
      source    => $self->config->{id},
      currency    => $curr,
      status    => 0, # proper status for the ticker w/o errors
      date_ts   => $currency->{timestamp} / 1000,
      base_currency   => $self->config->{base_currency},
      base_usd_rate => $self->usd_rates->{$self->config->{base_currency}}//1,
      highest_bid => $currency->{tradePrice},
      lowest_ask  => $currency->{tradePrice},
      opening_price => $currency->{openingPrice},
      closing_price => $currency->{tradePrice}, 
      min_price   => $currency->{lowPrice},
      max_price   => $currency->{highPrice},
      average_price => 0,
      units_traded  => $currency->{unit},
      volume_1day => $currency->{candleAccTradeVolume},
      volume_7day => 0, 
    );

  return 1;
}

sub _get_symbols {
  my $self = shift;
  my @market = ('KRW', 'BTC', 'ETH', 'USDT');
  my @currency = ('BTC', 'ETH', 'XRP', 'STEEM', 'SBD');
  my $new_result;
  
  foreach my $mkt (@market) { 
    foreach my $crry (@currency) {   
      my $symbol = $mkt . '-' . $crry;

      next unless $self->symbol_allowed($symbol) || $self->symbol_allowed('t'.$symbol);
      push @{$new_result}, {id => $symbol};
    }
  }
  
  return $new_result;
}

2;