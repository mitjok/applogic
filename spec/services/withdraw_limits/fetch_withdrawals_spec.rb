# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WithdrawLimits::FetchWithdrawals do
  describe '.call' do
    context 'under standart conditions' do
      subject do
        VCR.use_cassette('fetch-withdrawals-happy-path') do
          described_class.new.call('ID9B00C32556', 'eth')
        end
      end

      it 'works' do
        allow(Time).to receive(:current).and_return(Time.parse('2018-06-20T18:00:00+02:00'))
        expect(subject).to be_success
        expect(subject.value!.count).to eq(1)
        expect(subject.value!.first['amount']).to eq('0.001')
      end
    end
  end
end
