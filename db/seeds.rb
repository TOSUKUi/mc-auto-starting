development_user = User.find_or_initialize_by(email_address: "dev@example.com")
development_user.password = "password"
development_user.password_confirmation = "password"
development_user.save!
