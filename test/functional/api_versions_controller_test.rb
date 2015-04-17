require 'test_helper'

class ApiVersionsControllerTest < ActionController::TestCase
  setup do
    @api_version = api_versions(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:api_versions)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create api_version" do
    assert_difference('ApiVersion.count') do
      post :create, api_version: {  }
    end

    assert_redirected_to api_version_path(assigns(:api_version))
  end

  test "should show api_version" do
    get :show, id: @api_version
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @api_version
    assert_response :success
  end

  test "should update api_version" do
    put :update, id: @api_version, api_version: {  }
    assert_redirected_to api_version_path(assigns(:api_version))
  end

  test "should destroy api_version" do
    assert_difference('ApiVersion.count', -1) do
      delete :destroy, id: @api_version
    end

    assert_redirected_to api_versions_path
  end
end
