module PasskeyAuthenticatable

end

Devise.add_module :passkey_authenticatable, model: "devise/models/passkey_authenticatable", strategy: true, controller: :passkey_sessions, route: { session: [nil, :new, :create, :destroy]}