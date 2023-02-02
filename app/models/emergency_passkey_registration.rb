class EmergencyPasskeyRegistration < ApplicationRecord
  belongs_to :user

  include Devise::Models::EmergencyPasskeyRegistration

  def self.devise_resource_class
    User
  end
end
