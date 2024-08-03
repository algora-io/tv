defmodule Algora.AdsTest do
  use Algora.DataCase

  alias Algora.Ads

  describe "next_ad_slot/1" do
    test "returns the next 10-minute slot" do
      # Test case 1: Exactly at the start of a slot
      time = ~U[2024-08-03 10:00:00Z]
      assert Ads.next_ad_slot(time) == ~U[2024-08-03 10:10:00Z]

      # Test case 2: In the middle of a slot
      time = ~U[2024-08-03 10:05:30Z]
      assert Ads.next_ad_slot(time) == ~U[2024-08-03 10:10:00Z]

      # Test case 3: Just before the next slot
      time = ~U[2024-08-03 10:09:59Z]
      assert Ads.next_ad_slot(time) == ~U[2024-08-03 10:10:00Z]

      # Test case 4: Crossing an hour boundary
      time = ~U[2024-08-03 10:55:00Z]
      assert Ads.next_ad_slot(time) == ~U[2024-08-03 11:00:00Z]

      # Test case 5: Crossing a day boundary
      time = ~U[2024-08-03 23:55:00Z]
      assert Ads.next_ad_slot(time) == ~U[2024-08-04 00:00:00Z]
    end

    test "uses current time when no argument is provided" do
      assert Ads.next_ad_slot() == Ads.next_ad_slot(DateTime.utc_now())
    end
  end
end
