module Api
  module Discord
    module Bot
      class BaseController < ActionController::API
        include Pundit::Authorization

        before_action :authenticate_bot_request!

        rescue_from Pundit::NotAuthorizedError, with: :render_forbidden

        private
          def pundit_user
            Current.user
          end

          def authenticate_bot_request!
            authenticate_bot_token!
            authenticate_acting_user!
          end

          def authenticate_bot_token!
            expected_token = Rails.application.config.x.discord_bot.api_token.to_s
            provided_token = request.authorization.to_s.delete_prefix("Bearer ").strip

            if expected_token.blank? || provided_token.blank? || !ActiveSupport::SecurityUtils.secure_compare(provided_token, expected_token)
              render json: { ok: false, error: "Bot credential is invalid.", error_code: "unauthorized_bot" }, status: :unauthorized
              return
            end
          end

          def authenticate_acting_user!
            discord_user_id = request.headers["X-Discord-User-Id"].to_s.strip
            if discord_user_id.blank?
              render json: { ok: false, error: "Acting Discord user id is required.", error_code: "missing_discord_user_id" }, status: :bad_request
              return
            end

            user = User.find_by(discord_user_id: discord_user_id)
            unless user
              render json: { ok: false, error: "Acting Discord user is not allowed.", error_code: "unknown_discord_user" }, status: :forbidden
              return
            end

            Current.session = nil
            Current.user = user
          end

          def render_forbidden
            render json: { ok: false, error: "This action is not permitted.", error_code: "forbidden" }, status: :forbidden
          end

          def render_success(server:, action:, message:, result:)
            render json: {
              ok: true,
              server_id: server.id,
              server_name: server.name,
              action: action,
              message: message,
              result: result,
            }
          end

          def render_failure(error:, error_code:, status:, extra: {})
            render json: {
              ok: false,
              error: error,
              error_code: error_code,
            }.merge(extra), status: status
          end
      end
    end
  end
end
