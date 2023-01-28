class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :registerable, :rememberable


  has_many :passkeys
  has_many :emergency_passkey_registrations
end
