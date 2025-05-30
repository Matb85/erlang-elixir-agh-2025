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
      <h1 class="text-3xl font-bold mb-6 text-blue-700 text-center">Station Range</h1>
      <form phx-change="update" class="space-y-6 max-w-2xl mx-auto p-6 bg-white rounded-lg shadow-md mt-8">
        <div>
          <label class="block text-gray-700 font-semibold mb-2">Lat min</label>
          <input type="range" min="0" max="100" name="lat_min" value={@lat_min}
          class="w-full accent-blue-500"/>
          <span class="text-sm text-gray-500">Value: <%= @lat_min %></span>
        </div>
        <div>
          <label class="block text-gray-700 font-semibold mb-2">Lat max</label>
          <input type="range" min="0" max="100" name="lat_max" value={@lat_max}
          class="w-full accent-blue-500"/>
          <span class="text-sm text-gray-500">Value: <%= @lat_max %></span>
        </div>
        <div>
          <label class="block text-gray-700 font-semibold mb-2">Lon min</label>
          <input type="range" min="0" max="100" name="lon_min" value={@lon_min}
          class="w-full accent-blue-500"/>
          <span class="text-sm text-gray-500">Value: <%= @lon_min %></span>
        </div>
        <div>
          <label class="block text-gray-700 font-semibold mb-2">Lon max</label>
          <input type="range" min="0" max="100" name="lon_max" value={@lon_max}
          class="w-full accent-blue-500"/>
          <span class="text-sm text-gray-500">Value: <%= @lon_max %></span>
        </div>
      </form>

      <h2 class="text-2xl font-semibold mt-10 text-blue-700">Stations in Range</h2>
      <div class="space-y-6 max-w-2xl mx-auto p-6 bg-white rounded-lg shadow-md mt-4">
        <ul class="divide-y divide-gray-200 mb-4">
        <%= for station <- @stations do %>
          <li class="py-2 flex justify-between items-center">
          <span class="font-medium text-gray-800"><%= station.name %></span>
          <span class="text-sm text-gray-500">Lat: <%= station.lat %>, Lon: <%= station.lon %></span>
          </li>
        <% end %>
        </ul>
        <p class="text-right text-gray-600 font-semibold">
        Total stations in range: <span class="text-blue-700"><%= length(@stations) %></span>
        </p>
      </div>
    """
  end

end
