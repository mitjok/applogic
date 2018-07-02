# frozen_string_literal: true

require 'dry/monads/all'

module WithdrawLimits
  # Responsible for fetching user withdrawals for last 24h
  class FetchWithdrawals < :ManagementAPIv1Client
    include Dry::Monads
    include Dry::Monads::Do.for(:call)

    def initialize(*)
      super ENV.fetch('PEATIO_ROOT_URL'),
            Rails.configuration.x.peatio_management_api_v1_configuration
    end

    def call(args = {})
      payload = yield make_payload(args)
      jwt     = yield make_jwt(payload)
      respone = yield do_request(jwt)
      # select 24 h withdrawa
    end

    private

    def make_payload(args)
      Try() { args }
        .fmap { |a| a.slice(:uid, :currency) }
        .fmap { |a| a.merge(limit: 1000) }
        .fmap { |a| payload(a) }
        .to_result
    end

    def make_jwt(payload)
      Try() { generate_jwt(payload) }.to_result
    end

    def do_request(jwt)
      result = Try() { request(:post, 'withdraws', jwt, jwt: true) }

      if result.error?
        Rails.logger.debug(result)
        return Failure(:failed_to_fetch_withdrawals_error_raised)
      end

      unless result.value!.success?
        result.value!.log_failure
        return Failure(:failed_to_fetch_withdrawals_response_unsuccessfull)
      end

      Success(result.value!)
    end

    def process_response(response)
      Try() {response}
        .fmap(&:body)
    end
  end
end


# optional :uid,      type: String,  desc: 'The shared user ID.'
# optional :currency, type: String,  values: -> { Currency.codes(bothcase: true) }, desc: 'The currency code.'
# optional :page,     type: Integer, default: 1,   integer_gt_zero: true, desc: 'The page number (defaults to 1).'
# optional :limit,    type: Integer, default: 100, range: 1..1000, desc: 'The number of objects per page (defaults to 100, maximum is 1000).'
# optional :state,    type: String,  values: -> { Withdraw::STATES.map(&:to_s) }, desc: 'The state to filter by.'
