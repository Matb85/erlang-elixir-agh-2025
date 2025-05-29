defmodule PollutiondbWeb.StationLive do
  use PollutiondbWeb, :live_view

  defp to_float(value, default) do
    case Float.parse(value) do
      {num, _} -> num
      :error -> default
    end
  end

  def mount(_params, _session, socket) do
    socket = assign(socket, stations: Pollutiondb.Station.get_all(), name: "", lat: "", lon: "")
    {:ok, socket}
  end

  def handle_event("insert", %{"name" => name, "lat" => lat, "lon" => lon}, socket) do
    Pollutiondb.Station.add(name, to_float(lat, 0.0), to_float(lon, 0.0))
    socket = assign(socket, stations: Pollutiondb.Station.get_all(), name: name, lat: lat, lon: lon)
    {:noreply, socket}
  end


  def render(assigns) do
    ~H"""
    Create new station
    <form phx-submit="insert">
      Name: <input type="text" name="name" value={@name} /><br/>
      Lat: <input type="number" name="lat" step="0.1" value={@lat} /><br/>
      Lon: <input type="number" name="lon" step="0.1" value={@lon} /><br/>
      <input type="submit" />
    </form>
    <table>
      <tr>
        <th>Name</th><th>Longitude</th><th>Latitude</th>
      </tr>
      <%= for station <- @stations do %>
        <tr>
          <td><%= station.name %></td>
          <td><%= station.lon %></td>
          <td><%= station.lat %></td>
        </tr>
      <% end %>
    </table>
    """
  end
end
