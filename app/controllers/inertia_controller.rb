# frozen_string_literal: true

class InertiaController < ApplicationController
  inertia_share app: -> {
    {
      current_user: Current.user&.as_json(only: [ :id, :email_address, :discord_username ]),
      navigation: [
        { name: "Servers", href: "/servers" },
        { name: "招待", href: "/discord-invitations" },
      ],
      flash: {
        notice: flash[:notice],
        alert: flash[:alert],
        invite_url: flash[:invite_url],
      },
    }
  }
end
