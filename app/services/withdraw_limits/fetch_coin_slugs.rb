# frozen_string_literal: true

# More info: https://www.morozov.is/2018/05/27/do-notation-ruby.html
require 'dry/monads/all'

module WithdrawLimits
  # Responsible for fetching supported coin names from third-party service
  class FetchCoinSlugs
    include Dry::Monads
    include Dry::Monads::Do.for(:call)

    def call(args = {})
      url = args.fetch(:url, 'https://api.coinmarketcap.com/v2/listings/')

      response = yield do_request(url)

      slugs = yield make_slugs(response)

      Success(slugs)
    end

    private

    def do_request(url)
      result = Try { Faraday.get(url) }

      if result.error?
        Rails.logger.debug(result)
        return Failure(:failed_to_fetch_supported_coins_error_raised)
      end

      unless result.value!.success?
        result.value!.log_failure
        return Failure(:failed_to_fetch_supported_coins_response_unsuccessfull)
      end

      Success(result.value!)
    end

    def make_slugs(response)
      Maybe(response)
        .fmap(&:body)
        .fmap { |body| JSON.parse(body) }
        .fmap { |data| data['data'] }
        .fmap { |ary| code_slug_hash(ary) }
    end

    def code_slug_hash(data)
      data.inject({}) do |m, e|
        m.merge(e['symbol'].to_s.downcase => e['website_slug'])
      end
    end
  end
end
