class DiscordInvitationPolicy < ApplicationPolicy
  def index?
    logged_in?
  end

  def create?
    logged_in?
  end

  def revoke?
    issued_by_user?
  end

  class Scope < Scope
    def resolve
      return scope.none unless user

      scope.where(invited_by: user)
    end
  end

  private
    def issued_by_user?
      user.present? && record.invited_by_id == user.id
    end
end
