Rails.application.config.after_initialize do
  BootstrapOwnerLoginHint.log!
end
