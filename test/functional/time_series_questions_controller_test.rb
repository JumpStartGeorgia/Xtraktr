require 'test_helper'

class TimeSeriesQuestionsControllerTest < ActionController::TestCase
  setup do
    @time_series_question = time_series_questions(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:time_series_questions)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create time_series_question" do
    assert_difference('TimeSeriesQuestion.count') do
      post :create, time_series_question: {  }
    end

    assert_redirected_to time_series_question_path(assigns(:time_series_question))
  end

  test "should show time_series_question" do
    get :show, id: @time_series_question
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @time_series_question
    assert_response :success
  end

  test "should update time_series_question" do
    put :update, id: @time_series_question, time_series_question: {  }
    assert_redirected_to time_series_question_path(assigns(:time_series_question))
  end

  test "should destroy time_series_question" do
    assert_difference('TimeSeriesQuestion.count', -1) do
      delete :destroy, id: @time_series_question
    end

    assert_redirected_to time_series_questions_path
  end
end
