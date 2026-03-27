class ServerMemberPolicy < ApplicationPolicy
  def index?
    manage?
  end

  def show?
    manage?
  end

  def create?
    manage?
  end

  def update?
    manage?
  end

  def destroy?
    manage?
  end

  class Scope < Scope
    def resolve
      return scope.none unless user
      return scope.all if user.admin?

      scope.joins(:minecraft_server).where(minecraft_servers: { owner_id: user.id })
    end
  end

  private
    def manage?
      user.present? && (user.admin? || record.minecraft_server.owner_id == user.id)
    end
end
