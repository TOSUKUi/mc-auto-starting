# frozen_string_literal: true

class InertiaController < ApplicationController
  inertia_share app: -> {
    {
      current_user: Current.user&.as_json(only: [ :id, :email_address ]),
      navigation: [
        { name: "Home", href: "/" },
        { name: "Servers", href: "/servers" },
      ],
    }
  }
end
