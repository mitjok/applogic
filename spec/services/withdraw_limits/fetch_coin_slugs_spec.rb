# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WithdrawLimits::FetchCoinSlugs do
  describe '.call' do
    context 'happy path' do
      subject do
        VCR.use_cassette('fetch-supported-coins') do
          described_class.new.call
        end
      end

      it 'works' do
        expect(subject).to be_success
      end
    end

    context 'error raised' do
      subject do
        described_class.new.call
      end

      it 'return Failure monad' do
        stub_request(:get, 'https://api.coinmarketcap.com/v2/listings/').to_raise(Faraday::ConnectionFailed)
        expect(subject).to be_failure
        expect(subject.failure).to eq(:failed_to_fetch_supported_coins_error_raised)
      end
    end
  end
end
