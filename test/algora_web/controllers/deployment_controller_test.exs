defmodule AlgoraWeb.DeploymentControllerTest do
  use AlgoraWeb.ConnCase, async: true

  describe "start_livestream/2" do
    test "starts a livestream", %{conn: conn} do
      conn = post(conn, Routes.deployment_path(conn, :start_livestream))
      assert json_response(conn, 200) == %{"message" => "Livestream started"}
    end
  end

  describe "trigger_deployment/2" do
    test "triggers a deployment", %{conn: conn} do
      conn = post(conn, Routes.deployment_path(conn, :trigger_deployment))
      assert json_response(conn, 200) == %{"message" => "Deployment triggered"}
    end
  end

  describe "confirm_livestream_continuity/2" do
    test "confirms livestream continuity", %{conn: conn} do
      conn = post(conn, Routes.deployment_path(conn, :confirm_livestream_continuity))
      assert json_response(conn, 200) == %{"message" => "Livestream continuity confirmed"}
    end
  end

  describe "stop_livestream/2" do
    test "stops a livestream", %{conn: conn} do
      conn = post(conn, Routes.deployment_path(conn, :stop_livestream))
      assert json_response(conn, 200) == %{"message" => "Livestream stopped"}
    end
  end

  describe "destroy_old_machine/2" do
    test "destroys old machine", %{conn: conn} do
      conn = post(conn, Routes.deployment_path(conn, :destroy_old_machine))
      assert json_response(conn, 200) == %{"message" => "Old machine destroyed"}
    end
  end
end
