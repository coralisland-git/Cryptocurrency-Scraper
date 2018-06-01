package Exchange::TopBTC;
use strict;
use warnings;

use parent 'Exchange';

use Data::Dumper;
use Try::Tiny;

sub _init {
  my $self = shift;
  $self->{config} = {
	    'id' => 'topbtc',
            'name' => 'TopBTC',
            'countries' => 'CN', 
            'rateLimit' => 500, # no info
            'base_currency' => 'CNY',
            'has' => {
                'CORS' => 1,
                'fetchTickers' => 1,
                'withdraw' => 1,
            },
            'urls' => {
                'logo' => 'https://www.topbtc.com/upload/logo.png?v2',
                'api' => 'https://www.topbtc.com/market/market.php',
                'www' => 'https://www.topbtc.com/',
                'doc' => '',
            },
            'can' => {
            	'rest'  => 1,
            	'push'  => undef,
            	'wsock' => undef,
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

  foreach my $symbol (@{$self->{config}->{symbols}}) {
    $self->post(
      url => "https://www.topbtc.com/market/market.php",
      vars => { 
          "coin" => $symbol->{coin},
          "market" => $symbol->{market}
      },
      on_result => sub { $self->process_ticker(@_) },
      on_error  => sub { $self->common_error(@_) },
    );
  }
}

sub process_ticker {
  my $self = shift;
  my $tx = shift;
  my ($tp1, $tp2, $curr) = (@_);

  my $currency    = $tx->result->json;

  if ($currency) {
    $self->store_ticker(
        source    => $self->config->{id},
        currency    => $currency->{market}."_".$currency->{symbol},
        status    => 0, # proper status for the ticker w/o errors
        date_ts   => time,
        base_currency   => $self->config->{base_currency},
        base_usd_rate => $self->usd_rates->{$self->config->{base_currency}}//1,
        highest_bid => $currency->{buy}[0]->{price},
        lowest_ask  => $currency->{sell}[0]->{price},
        opening_price => 0,
        closing_price => $currency->{last}->{price}, 
        min_price   => 0,
        max_price   => 0,
        average_price => 0,
        units_traded  => 0,
        volume_1day => 0,
        volume_7day => 0, 
      );
  }

  return 1;
}


sub _get_symbols {
  my $self = shift;
  my @result = (
    { coin => 'BTC', market => 'QQC'},
    { coin => 'BCH', market => 'QQC'},
    { coin => 'LTC', market => 'QQC'},
    { coin => 'ETH', market => 'QQC'},
    { coin => 'LEO', market => 'QQC'},
    { coin => 'EOS', market => 'QQC'},
    { coin => 'INK', market => 'QQC'},
    { coin => 'FOTA', market => 'QQC'},
    { coin => 'CHC', market => 'QQC'},
    { coin => 'ETP', market => 'QQC'},
    { coin => 'SNT', market => 'ETH'},
    { coin => 'OMG', market => 'ETH'},
    { coin => 'SGCC', market => 'ETH'},
    { coin => 'BICC', market => 'ETH'},
    { coin => 'CSD', market => 'ETH'},
    { coin => 'P2P', market => 'ETH'},
    { coin => 'NGOT', market => 'ETH'},
    { coin => 'LTC', market => 'BTC'},
    { coin => 'ETH', market => 'BTC'},
    { coin => 'BGC', market => 'BTC'},
    { coin => 'YTC', market => 'BTC'},
    { coin => 'ETER', market => 'BTC'},
    { coin => 'SV', market => 'BTC'},
    { coin => 'HSR', market => 'BTC'},
    { coin => 'CFC', market => 'BTC'},
    { coin => 'ATB', market => 'BTC'},
    { coin => 'MVT', market => 'BTC'},
    { coin => 'CIG', market => 'BTC'},
    { coin => 'WJC', market => 'BTC'},
    { coin => 'VOISE', market => 'BTC'},
    { coin => 'MANA', market => 'BTC'},
    { coin => 'EXCC', market => 'BTC'},
    { coin => 'BLT', market => 'BTC'},
    { coin => 'UQC', market => 'BTC'},
    { coin => 'OLE', market => 'BTC'},
    { coin => 'ORME', market => 'BTC'},
  );
  
  return $result;
}

2;



