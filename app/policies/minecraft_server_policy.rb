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

  def read_audit_logs?
    visible_to_user?
  end

  def start?
    owner? || operator?
  end

  def stop?
    owner? || operator?
  end

  def restart?
    owner? || operator?
  end

  def sync?
    owner? || operator?
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

    def operator?
      return false unless user
      return false if owner?

      record.server_members.exists?(user_id: user.id, role: ServerMember.roles[:operator])
    end

    def viewer?
      return false unless user
      return false if owner?

      record.server_members.exists?(user_id: user.id, role: ServerMember.roles[:viewer])
    end

    def visible_to_user?
      owner? || operator? || viewer?
    end
end
