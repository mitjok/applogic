# frozen_string_literal: true

module WithdrawLimits
  # Responsible for comparing 24 h withdrawals in EURO
  # with predefined limits for user levels
  class DailyLimitCheck
    def call(user, code)
      funds = ConvertWithdrawSumToEuro.new.call(user.uid, code)

      case user.level
      when 1
        funds <= WITHDRAW_LIMIT_LEVEL_1
      when 2
        funds <= WITHDRAW_LIMIT_LEVEL_2
      else
        false
      end
    end
  end
end
