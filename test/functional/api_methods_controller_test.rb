require 'test_helper'

class ApiMethodsControllerTest < ActionController::TestCase
  setup do
    @api_method = api_methods(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:api_methods)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create api_method" do
    assert_difference('ApiMethod.count') do
      post :create, api_method: {  }
    end

    assert_redirected_to api_method_path(assigns(:api_method))
  end

  test "should show api_method" do
    get :show, id: @api_method
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @api_method
    assert_response :success
  end

  test "should update api_method" do
    put :update, id: @api_method, api_method: {  }
    assert_redirected_to api_method_path(assigns(:api_method))
  end

  test "should destroy api_method" do
    assert_difference('ApiMethod.count', -1) do
      delete :destroy, id: @api_method
    end

    assert_redirected_to api_methods_path
  end
end
