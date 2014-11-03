require 'test_helper'

class ShapesetsControllerTest < ActionController::TestCase
  setup do
    @shapeset = shapesets(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:shapesets)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create shapeset" do
    assert_difference('Shapeset.count') do
      post :create, shapeset: { description: @shapeset.description, geojson: @shapeset.geojson, title: @shapeset.title }
    end

    assert_redirected_to shapeset_path(assigns(:shapeset))
  end

  test "should show shapeset" do
    get :show, id: @shapeset
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @shapeset
    assert_response :success
  end

  test "should update shapeset" do
    put :update, id: @shapeset, shapeset: { description: @shapeset.description, geojson: @shapeset.geojson, title: @shapeset.title }
    assert_redirected_to shapeset_path(assigns(:shapeset))
  end

  test "should destroy shapeset" do
    assert_difference('Shapeset.count', -1) do
      delete :destroy, id: @shapeset
    end

    assert_redirected_to shapesets_path
  end
end
