# frozen_string_literal: true

module APIv1
  module Helpers
    extend Memoist

    def authenticate!
      current_user || raise(AuthorizationError)
    end

    def current_user
      return unless env.key?(auth_env_key)

      User.find_by(uid: env[auth_env_key])
    end
    memoize :current_user

    def auth_env_key
      'api.v1.authenticated_uid'
    end

    def current_uid
      env[auth_env_key]
    end
  end
end
