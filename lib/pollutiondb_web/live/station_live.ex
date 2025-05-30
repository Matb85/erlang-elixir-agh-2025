defmodule PollutiondbWeb.StationLive do
  use PollutiondbWeb, :live_view

  defp to_float(value, default) do
    case Float.parse(value) do
      {num, _} -> num
      :error -> default
    end
  end

  def mount(_params, _session, socket) do
    socket =
      assign(socket,
        stations: Pollutiondb.Station.get_all(),
        name: "",
        lat: "",
        lon: "",
        query: ""
      )

    {:ok, socket}
  end

  def handle_event("insert", %{"name" => name, "lat" => lat, "lon" => lon}, socket) do
    Pollutiondb.Station.add(name, to_float(lat, 0.0), to_float(lon, 0.0))
    socket =
      assign(socket,
        stations: Pollutiondb.Station.get_all(),
        name: name,
        lat: lat,
        lon: lon
      )
    {:noreply, socket}
  end

  def handle_event("search", %{"query" => query}, socket) do
    stations =
      if query == "" do
        Pollutiondb.Station.get_all()
      else
        Pollutiondb.Station.get_all()
        |> Enum.filter(fn station ->
          String.contains?(String.downcase(station.name), String.downcase(query))
        end)
      end

    {:noreply, assign(socket, stations: stations, query: query)}
  end

  def render(assigns) do
    ~H"""

    <h1 class="text-3xl font-bold mb-6 text-center text-blue-700">Create new station</h1>
    <form phx-submit="insert" class="space-y-6 max-w-2xl mx-auto p-6 bg-white rounded-lg shadow-md mt-8">
      <div>
        <label class="block text-gray-700 font-medium mb-1">Name:</label>
        <input type="text" name="name" value={@name} class="w-full px-3 py-2 border border-gray-300 rounded focus:outline-none focus:ring-2 focus:ring-blue-400" />
      </div>
      <div>
        <label class="block text-gray-700 font-medium mb-1">Lat:</label>
        <input type="number" name="lat" step="0.1" value={@lat} class="w-full px-3 py-2 border border-gray-300 rounded focus:outline-none focus:ring-2 focus:ring-blue-400" />
      </div>
      <div>
        <label class="block text-gray-700 font-medium mb-1">Lon:</label>
        <input type="number" name="lon" step="0.1" value={@lon} class="w-full px-3 py-2 border border-gray-300 rounded focus:outline-none focus:ring-2 focus:ring-blue-400" />
      </div>
    <button type="submit" class="w-full bg-blue-600 text-white py-2 rounded hover:bg-blue-700 transition">Add Station</button>
    </form>


    <h2 class="text-2xl font-semibold mt-10 text-blue-700">Search station by name</h2>
    <div class="max-w-2xl mx-auto mt-4 p-6 bg-white rounded-lg shadow-md">
      <form phx-change="search" class="mb-4">
      <input type="text" name="query" value={@query} placeholder="Station name"
        class="w-full px-3 py-2 border border-gray-300 rounded focus:outline-none focus:ring-2 focus:ring-blue-400" />
      </form>

      <div class="overflow-x-auto">
      <table class="min-w-full bg-white border border-gray-200 rounded">
        <thead>
        <tr>
          <th class="px-4 py-2 border-b text-left text-gray-700">Name</th>
          <th class="px-4 py-2 border-b text-left text-gray-700">Longitude</th>
          <th class="px-4 py-2 border-b text-left text-gray-700">Latitude</th>
        </tr>
        </thead>
        <tbody>
        <%= for station <- @stations do %>
          <tr class="hover:bg-gray-100">
          <td class="px-4 py-2 border-b"><%= station.name %></td>
          <td class="px-4 py-2 border-b"><%= station.lon %></td>
          <td class="px-4 py-2 border-b"><%= station.lat %></td>
          </tr>
        <% end %>
        </tbody>
      </table>
      </div>
    </div>
    """
  end
end
