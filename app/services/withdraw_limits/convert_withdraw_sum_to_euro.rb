# frozen_string_literal: true

require 'dry/monads/do'

module WithdrawLimits
  # Responsible for fetching supported coin prices from third-party service
  class ConvertWithdrawSumToEuro
    include Dry::Monads::Do.for(:call)

    def call(code, withdrawals)
      price = yield FetchCoinPrice.new.call(code: code)
      price * sum(withdrawals)
    end

    private

    def sum(withdrawals)
      withdrawals.reduce(BigDecimal('0')) { |sum, e| sum + BigDecimal(e['amount']) }
    end
  end
end
