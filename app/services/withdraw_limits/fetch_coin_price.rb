# frozen_string_literal: true

require 'dry/monads/result'
require 'dry/monads/do'

module WithdrawLimits
  # Responsible for fetching supported coin names from third-party service
  class FetchCoinPrice
    include Dry::Monads::Result::Mixin
    include Dry::Monads::Maybe::Mixin
    include Dry::Monads::Do.for(:call)

    def call(args = {})
      name = args.fetch(:name, 'bitcoin')

      validated_name = yield validate(name)
      url = args.fetch(:url, "https://api.coinmarketcap.com/v1/ticker/#{validated_name}/?convert=EUR")

      raw = yield fetch_raw_data(url)
      Maybe(raw.first)
        .fmap { |data| data['price_eur'] }
        .fmap { |price| BigDecimal(price) }
        .value_or(BigDecimal('0'))
    end

    private

    def validate(name)
      if FetchCoinNames.new.call.include?(name.to_s)
        Success(name)
      else
        Failure(:coin_name_not_supported)
      end
    end

    def fetch_raw_data(url)
      response = Faraday.get(url)

      if response.success?
        Success(JSON.parse(response.body))
      else
        Failure(:failed_to_fetch_coin_price)
      end
    end
  end
end
