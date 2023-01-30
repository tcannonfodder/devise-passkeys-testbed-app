module PasskeyAuthenticatable

end

Devise.add_module :passkey_authenticatable, model: "passkey_authenticatable/model", strategy: true, controller: :passkey_sessions, route: { session: [nil, :new, :create, :destroy]}