require 'test_helper'
require "webmock/minitest"

class Admin::PublishersControllerTest < ActionDispatch::IntegrationTest
  # For Devise >= 4.1.1
  include Devise::Test::IntegrationHelpers
  # Use the following instead if you are on Devise <= 4.1.0
  # include Devise::TestHelpers

  test "regular users cannot access" do
    publisher = publishers(:completed)
    sign_in publisher

    assert_raises(CanCan::AccessDenied) {
      get admin_publishers_path
    }
  end

  test "admin can access" do
    admin = publishers(:admin)
    sign_in admin

    get admin_publishers_path
    assert_response :success
  end

  test "admin filters appropriately on name & email" do
    admin = publishers(:admin)
    publisher = publishers(:completed)
    sign_in admin

    get admin_publishers_path
    assert_response :success
    assert_select 'tbody' do
      assert_select 'tr' do
        assert_select 'td', publisher.id
      end
    end

    get admin_publishers_path, params: {q: "#{publisher.name}"}
    assert_response :success
    assert_select 'tbody' do
      assert_select 'tr', true
    end

    get admin_publishers_path, params: {q: "#{publisher.name}failure"}
    assert_response :success
    assert_select 'tbody' do
      assert_select 'tr', false
    end
  end

  test "raises error unless admin has 2fa enabled" do
    admin = publishers(:admin)
    admin.totp_registration.destroy! # remove 2fa
    admin.reload
    sign_in admin

    assert_raises(Ability::TwoFactorDisabledError) do
      get admin_publishers_path
    end
  end

  test "raises error unless admin is on admin whitelist" do
    admin = publishers(:admin)
    sign_in admin

    assert_raises(Ability::AdminNotOnIPWhitelistError) do
      get admin_publishers_path, headers: { 'REMOTE_ADDR' => '1.2.3.4' } # not on whitelist
    end
  end
end
