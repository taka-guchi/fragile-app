require 'test_helper'

class UsersIndexTest < ActionDispatch::IntegrationTest
  include Pagy::Backend

  def setup
    @user = users(:michael)
  end

  test "index including pagination" do
    log_in_as(@user)
    get users_path
    assert_template 'users/index'
    assert_select 'nav.pagy-bootstrap-nav.pagination'
  end
end
