defmodule PollutiondbWeb.StationRangeLive do
  use PollutiondbWeb, :live_view

  def mount(_params, _session, socket) do
    socket =
      assign(socket,
        stations: Pollutiondb.Station.get_all(),
        lat_min: 0,
        lat_max: 5,
        lon_min: 0,
        lon_max: 5
      )

    {:ok, socket}
  end

  def handle_event("update", params, socket) do
    lat_min = to_float(Map.get(params, "lat_min", "0"), 0.0)
    lat_max = to_float(Map.get(params, "lat_max", "5"), 5.0)
    lon_min = to_float(Map.get(params, "lon_min", "0"), 0.0)
    lon_max = to_float(Map.get(params, "lon_max", "5"), 5.0)

    stations =
      Pollutiondb.Station.get_all()
      |> Enum.filter(fn station ->
        station.lat >= lat_min and station.lat <= lat_max and
        station.lon >= lon_min and station.lon <= lon_max
      end)

    {:noreply,
      assign(socket,
        stations: stations,
        lat_min: lat_min,
        lat_max: lat_max,
        lon_min: lon_min,
        lon_max: lon_max
      )
    }
  end

  defp to_float(value, default) do
    case Float.parse(to_string(value)) do
      {num, _} -> num
      :error -> default
    end
  end

  def render(assigns) do
    ~H"""
    <h1>Station Range</h1>
    <form phx-change="update">
      Lat min
      <input type="range" min="0" max="100" name="lat_min" value={@lat_min}/><br/>
      Lat max
      <input type="range" min="0" max="100" name="lat_max" value={@lat_max}/><br/>
      Lon min
      <input type="range" min="0" max="100" name="lon_min" value={@lon_min}/><br/>
      Lon max
      <input type="range" min="0" max="100" name="lon_max" value={@lon_max}/><br/>
    </form>

    <h2>Stations in Range</h2>
    <ul>
      <%= for station <- @stations do %>
        <li><%= station.name %> (Lat: <%= station.lat %>, Lon: <%= station.lon %>)</li>
      <% end %>
    </ul>
    <p>Total stations in range: <%= length(@stations) %></p>

    """
  end

end
