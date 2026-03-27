# frozen_string_literal: true

class InertiaController < ApplicationController
  inertia_share app: -> {
    {
      current_user: Current.user && {
        id: Current.user.id,
        user_type: Current.user.user_type,
        discord_user_id: Current.user.discord_user_id,
        discord_username: Current.user.discord_username,
        discord_global_name: Current.user.discord_global_name,
        operator_display_name: Current.user.operator_display_name,
      },
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
