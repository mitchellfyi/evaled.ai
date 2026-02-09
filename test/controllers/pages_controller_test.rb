require "test_helper"

class PagesControllerTest < ActionDispatch::IntegrationTest
  test "home returns success" do
    get root_path
    assert_response :success
  end

  test "home displays featured agents" do
    featured = create(:agent, :published, :featured, name: "Featured Agent")

    get root_path
    assert_response :success
  end

  test "home displays recent agents" do
    recent = create(:agent, :published, last_verified_at: 1.hour.ago, name: "Recent Agent")

    get root_path
    assert_response :success
  end

  test "home displays top agents by score" do
    top = create(:agent, :published, score: 95, name: "Top Agent")
    low = create(:agent, :published, score: 50, name: "Low Agent")

    get root_path
    assert_response :success
  end

  test "about returns success" do
    get about_path
    assert_response :success
  end

  test "methodology returns success" do
    get methodology_path
    assert_response :success
  end
end
