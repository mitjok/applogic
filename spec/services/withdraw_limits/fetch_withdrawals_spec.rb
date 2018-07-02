# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WithdrawLimits::FetchWithdrawals do
  describe '.call' do
    context 'under standart conditions' do
      subject do
        VCR.use_cassette('fetch-withdrawals-happy-path') do
          described_class.new.call(uid: 'ID9B00C32556')
        end
      end

      it 'works' do
        expect(subject).to be_success
      end
    end
  end
end
