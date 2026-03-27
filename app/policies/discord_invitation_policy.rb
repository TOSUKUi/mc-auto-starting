class DiscordInvitationPolicy < ApplicationPolicy
  def index?
    invitation_access?
  end

  def create?
    invitation_access?
  end

  def revoke?
    invitation_access? && issued_by_user?
  end

  class Scope < Scope
    def resolve
      return scope.none unless user

      scope.where(invited_by: user)
    end
  end

  private
    def invitation_access?
      user.present? && user.manageable_user_types.any?
    end

    def issued_by_user?
      user.present? && record.invited_by_id == user.id
    end
end
