class MinecraftServerPolicy < ApplicationPolicy
  def index?
    logged_in?
  end

  def show?
    visible_to_user?
  end

  def create?
    admin_user? || operator_user?
  end

  def update?
    admin_user? || owner?
  end

  def destroy?
    admin_user? || owner?
  end

  def manage_members?
    admin_user? || owner?
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

  def repair_publication?
    admin_user? || owner? || manager_membership?
  end

  def manage_whitelist?
    (admin_user? || owner?) && record.lifecycle_ready?
  end

  def rcon_command?
    (admin_user? || owner?) && record.lifecycle_ready?
  end

  def manage_startup_settings?
    admin_user? || owner?
  end

  class Scope < Scope
    def resolve
      return scope.none unless user
      return scope.all if user.admin?

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
      admin_user? || owner? || manager_membership? || viewer?
    end

    def lifecycle_access?
      (admin_user? || owner? || manager_membership?) && record.lifecycle_ready?
    end
end
