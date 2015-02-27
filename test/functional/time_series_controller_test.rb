require 'test_helper'

class TimeSeriesControllerTest < ActionController::TestCase
  setup do
    @time_series = time_series(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:time_series)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create time_series" do
    assert_difference('TimeSeries.count') do
      post :create, time_series: {  }
    end

    assert_redirected_to time_series_path(assigns(:time_series))
  end

  test "should show time_series" do
    get :show, id: @time_series
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @time_series
    assert_response :success
  end

  test "should update time_series" do
    put :update, id: @time_series, time_series: {  }
    assert_redirected_to time_series_path(assigns(:time_series))
  end

  test "should destroy time_series" do
    assert_difference('TimeSeries.count', -1) do
      delete :destroy, id: @time_series
    end

    assert_redirected_to time_series_index_path
  end
end
