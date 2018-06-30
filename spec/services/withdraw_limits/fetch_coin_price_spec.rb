# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WithdrawLimits::FetchCoinPrice do
  describe '.call' do
    context 'under standart conditions' do
      subject do
        VCR.use_cassette('fetch-coint-price-happy-path') do
          described_class.new.call(code: 'btc')
        end
      end

      it 'works' do
        expect(subject).to be_success
        expect(subject.value!).to be_instance_of(BigDecimal)
      end
    end

    context 'if coin is not supported' do
      subject do
        VCR.use_cassette('fetch-coint-price-wrong-code') do
          described_class.new.call(code: 'bitcoin-wrong')
        end
      end

      it 'returns Failure monad' do
        expect(subject).to be_failure
        expect(subject.failure).to eq(:coin_not_supported)
      end
    end

    context 'if can\'t fetch prices' do
      subject do
        VCR.use_cassette('fetch-coint-price-raise-error') do
          described_class.new.call(code: 'btc')
        end
      end

      it 'returns Failure monad with message' do
        stub_request(:get, 'https://api.coinmarketcap.com/v1/ticker/bitcoin/?convert=EUR').to_raise(Faraday::Error)
        expect(subject).to be_failure
        expect(subject.failure).to eq(:failed_to_fetch_supported_prices_error_raised)
      end
    end

    context 'if can\'t get slugs' do
      subject do
        VCR.use_cassette('fetch-coint-slugs-raise-error') do
          described_class.new.call(code: 'btc')
        end
      end

      it 'returns Failure monad with message' do
        stub_request(:get, 'https://api.coinmarketcap.com/v2/listings/').to_raise(Faraday::ConnectionFailed)
        expect(subject).to be_failure
        expect(subject.failure).to eq(:failed_to_fetch_supported_coins_error_raised)
      end
    end
  end
end
