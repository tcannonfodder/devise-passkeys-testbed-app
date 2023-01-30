# Pin npm packages by running ./bin/importmap

pin "application", preload: true
pin "registration_form", preload: true
pin "@github/webauthn-json/browser-ponyfill", to: "https://ga.jspm.io/npm:@github/webauthn-json@2.1.0/dist/esm/webauthn-json.browser-ponyfill.js"
