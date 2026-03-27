class MinecraftServerPolicy < ApplicationPolicy
  def index?
    logged_in?
  end

  def show?
    visible_to_user?
  end

  def create?
    logged_in?
  end

  def update?
    owner?
  end

  def destroy?
    owner?
  end

  def manage_members?
    owner?
  end

  def start?
    lifecycle_access?
  end

  def stop?
    lifecycle_access?
  end

  def restart?
    lifecycle_access?
  end

  def sync?
    lifecycle_access?
  end

  class Scope < Scope
    def resolve
      return scope.none unless user

      scope
        .left_outer_joins(:server_members)
        .where("minecraft_servers.owner_id = :user_id OR server_members.user_id = :user_id", user_id: user.id)
        .distinct
    end
  end

  private
    def owner?
      user.present? && record.owner_id == user.id
    end

    def manager_membership?
      return false unless user
      return false if owner?

      record.server_members.exists?(user_id: user.id, role: ServerMember.roles[:manager])
    end

    def viewer?
      return false unless user
      return false if owner?

      record.server_members.exists?(user_id: user.id, role: ServerMember.roles[:viewer])
    end

    def visible_to_user?
      owner? || manager_membership? || viewer?
    end

    def lifecycle_access?
      (owner? || manager_membership?) && record.lifecycle_ready?
    end
end
