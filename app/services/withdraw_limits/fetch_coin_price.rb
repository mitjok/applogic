# frozen_string_literal: true

require 'dry/monads/all'

module WithdrawLimits
  # Responsible for fetching supported coin prices from third-party service
  class FetchCoinPrice
    include Dry::Monads
    include Dry::Monads::Do.for(:call)

    def call(args = {})
      code = args.fetch(:code)

      slugs = yield FetchCoinSlugs.new.call

      yield validate(slugs, code)

      url = args.fetch(:url, "https://api.coinmarketcap.com/v1/ticker/#{slugs[code]}/?convert=EUR")

      response = yield do_request(url)

      price = yield fetch_price(response)

      Success(price)
    end

    private

    def validate(slugs, code)
      if slugs.keys.include?(code.to_s)
        Success(code)
      else
        Rails.logger.debug "No #{code} in #{slugs.keys}"
        Failure(:coin_not_supported)
      end
    end

    def fetch_price(response)
      Try { response }
        .fmap(&:body)
        .fmap { |body| JSON.parse(body) }
        .fmap(&:first)
        .fmap { |data| data['price_eur'] }
        .fmap { |price| BigDecimal(price) }
        .to_result
    end

    def do_request(url)
      result = Try { Faraday.get(url) }

      if result.error?
        Rails.logger.debug(result)
        return Failure(:failed_to_fetch_supported_prices_error_raised)
      end

      unless result.value!.success?
        result.value!.log_failure
        return Failure(:failed_to_fetch_supported_prices_response_unsuccessfull)
      end

      Success(result.value!)
    end
  end
end
