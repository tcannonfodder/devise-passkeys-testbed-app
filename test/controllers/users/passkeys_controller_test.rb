require "test_helper"

class Users::PasskeysControllerTest < ActionDispatch::IntegrationTest
  test "should get create" do
    get users_passkeys_create_url
    assert_response :success
  end

  test "should get destroy" do
    get users_passkeys_destroy_url
    assert_response :success
  end
end
