# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WithdrawLimits::FetchCoinPrice do
  describe '.call' do
    context 'under standart conditions' do
      subject do
        VCR.use_cassette('coinmarketcap-bitcoin-price') do
          described_class.new.call(name: 'bitcoin')
        end
      end

      it 'works' do
        expect(subject).to be_instance_of(BigDecimal)
        expect(subject).to be > BigDecimal('0')
      end
    end

    context 'if coin is not supported' do
      subject do
        VCR.use_cassette('bitcoin-price-wrong-name') do
          described_class.new.call(name: 'bitcoin-wrong')
        end
      end

      it 'fails with error' do
        expect(subject).to be_failure
        expect(subject.failure).to eq(:coin_name_not_supported)
      end
    end

    context 'if name not supplied' do
      subject do
        VCR.use_cassette('bitcoin-price-nil-name') do
          described_class.new.call(name: nil)
        end
      end

      it 'fails with error' do
        expect(subject).to be_failure
        expect(subject.failure).to eq(:coin_name_not_supported)
      end
    end

    context 'if can\'t fetch prices' do
      subject do
        VCR.use_cassette('bitcoin-price-raise-error') do
          described_class.new.call(name: :bitcoin)
        end
      end

      it 'fails by raising error' do
        stub_request(:get, 'https://api.coinmarketcap.com/v1/ticker/bitcoin/?convert=EUR').to_raise(Faraday::Error)
        expect { subject }.to raise_error(Faraday::Error)
      end
    end
  end
end
