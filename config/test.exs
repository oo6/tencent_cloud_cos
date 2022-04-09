import Config

config :tencent_cloud_cos,
  secret_id: "test_secret_id",
  secret_key: "test_secret_key",
  http_client: [adapter: Tesla.Mock]
