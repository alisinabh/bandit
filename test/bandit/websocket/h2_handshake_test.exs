defmodule WebSocketHTTP2HandshakeTest do
  # This is fundamentally a test of the Plug helpers in Bandit.WebSocket.Handshake, so we define
  # a simple Plug that uses these handshakes to upgrade to a no-op WebSock implementation

  use ExUnit.Case, async: true
  use ServerHelpers

  setup :https_server

  @moduletag :enable_connect_protocol

  defmodule MyNoopWebSock do
    use NoopWebSock
  end

  def call(conn, _opts) do
    conn
    |> Plug.Conn.upgrade_adapter(:websocket, {MyNoopWebSock, [], []})
  end

  describe "HTTP/2 handshake" do
    test "accepts well formed requests", context do
      socket = SimpleH2Client.setup_connection(context)

      SimpleH2Client.send_headers(socket, 1, true, [
        {":method", "CONNECT"},
        {":path", "/"},
        {":scheme", "https"},
        {":authority", "localhost:#{context.port}"},
        {":protocol", "websocket"},
        {"sec-websocket-version", "13"}
      ])

      assert {:ok, 1, _flags, [{":status", "200"} | _], _context} =
               SimpleH2Client.recv_headers(socket)
    end
  end
end
