class SessionsController < ApplicationController
  allow_unauthenticated_access only: :new

  def new
  end

  def destroy
    terminate_session
    if request.headers["X-Inertia"].present?
      inertia_location(login_path)
    else
      redirect_to login_path, status: :see_other
    end
  end
end
