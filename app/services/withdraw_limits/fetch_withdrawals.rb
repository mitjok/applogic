# frozen_string_literal: true

require 'dry/monads/all'

module WithdrawLimits
  # Responsible for fetching user withdrawals for last 24h
  class FetchWithdrawals < ::ManagementAPIv1Client
    include Dry::Monads
    include Dry::Monads::Do.for(:call)

    def initialize(*)
      super ENV.fetch('PEATIO_ROOT_URL'),
            Rails.configuration.x.peatio_management_api_v1_configuration
      self.action = :read_withdraws
    end

    def call(uid, currency)
      payload     = yield make_payload(uid: uid, currency: currency)
      jwt         = yield make_jwt(payload)
      withdrawals = yield do_request(jwt)
      withdrawals = yield select_last_24h(withdrawals)

      Success(withdrawals)
    end

    private

    # TODO: add non error states
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
        return Failure(:failed_to_fetch_withdrawals)
      end

      Success(result.value!)
    end

    def select_last_24h(withdrawals)
      range = Time.current.yield_self { |now| (now.to_i..(now - 24.hours).to_i) }

      Try() { withdrawals }
        .fmap do |wls|
          wls.select { |w| range.cover?(Time.parse(w['created_at']).to_i) }
        end.to_result
    end
  end
end
