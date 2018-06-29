# frozen_string_literal: true

require 'dry/monads/result'
require 'dry/monads/do'

module WithdrawLimits
  # Responsible for fetching supported coin names from third-party service
  class FetchCoinNames
    include Dry::Monads::Result::Mixin
    include Dry::Monads::Maybe::Mixin
    include Dry::Monads::Do.for(:call)

    def call(args = {})
      url = args.fetch(:url, 'https://api.coinmarketcap.com/v2/listings/')

      raw = yield fetch_raw_data(url)
      Maybe(raw['data']).fmap do |data|
        data.map { |h| h['website_slug'] }
      end.value_or([])
    end

    private

    def fetch_raw_data(url)
      response = Faraday.get(url)

      if response.success?
        Success(JSON.parse(response.body))
      else
        Failure(:fail_to_fetch_supported_coin_names)
      end
    end
  end
end
