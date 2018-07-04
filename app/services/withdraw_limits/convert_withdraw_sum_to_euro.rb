# frozen_string_literal: true

require 'dry/monads/all'

module WithdrawLimits
  # Responsible for converting 24 h withdrawals to EURO
  class ConvertWithdrawSumToEuro
    include Dry::Monads
    include Dry::Monads::Do.for(:call)

    def call(uid, code)
      withdrawals = yield FetchWithdrawals.new.call(uid, code)
      price       = yield FetchCoinPrice.new.call(code: code)

      Success(price * sum(withdrawals))
    end

    private

    def sum(withdrawals)
      withdrawals.reduce(BigDecimal('0')) { |sum, e| sum + BigDecimal(e['amount']) }
    end
  end
end
