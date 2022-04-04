defmodule COS.AuthTest do
  use ExUnit.Case, async: true

  alias COS.Auth

  describe "end_timestamp" do
    test "default expiration time" do
      start_timestamp = 1_649_066_000
      assert 1_649_066_900 == Auth.end_timestamp(start_timestamp)
    end

    test "calc with expired_at" do
      start_timestamp = 1_649_066_000
      end_time = ~U[2022-04-04 10:00:00Z]
      end_timestamp = DateTime.to_unix(end_time)

      assert ^end_timestamp = Auth.end_timestamp(start_timestamp, expired_at: end_time)

      assert ^end_timestamp =
               Auth.end_timestamp(start_timestamp, expire_in: 60, expired_at: end_time)
    end

    test "calc with expire_in" do
      start_timestamp = 1_649_066_000
      assert 1_649_066_060 == Auth.end_timestamp(start_timestamp, expire_in: 60)
      assert 1_649_066_060 == Auth.end_timestamp(start_timestamp, expire_in: {60, :second})
      assert 1_649_066_060 == Auth.end_timestamp(start_timestamp, expire_in: {1, :minute})
      assert 1_649_069_600 == Auth.end_timestamp(start_timestamp, expire_in: {1, :hour})
      assert 1_649_152_400 == Auth.end_timestamp(start_timestamp, expire_in: {1, :day})
    end
  end
end
