# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WithdrawLimits::ConvertWithdrawSumToEuro do
  describe '.call' do
    context 'under standart conditions' do
      subject do
        VCR.use_cassette('convert-witdraw-sum-in-euro') do
          described_class.new.call('ID9B00C32556', 'eth')
        end
      end

      it 'works' do
        allow(Time).to receive(:current).and_return(Time.parse('2018-06-20T18:00:00+02:00'))
        expect(subject.value!).to eq(0.400435569198e0)
      end
    end
  end
end
