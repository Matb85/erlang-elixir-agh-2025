defmodule PollutiondbWeb.ReadingLive do
  use PollutiondbWeb, :live_view

  alias Pollutiondb.Station

  def mount(_params, _session, socket) do
    today = Date.utc_today()
    readings = Pollutiondb.Reading.find_by_date(today) |> Enum.take(10)
    stations = Pollutiondb.Station.get_all()
    socket =
      assign(socket,
        readings: readings,
        date: today,
        stations: stations,
        station_id: stations |> List.first() |> Map.get(:id, 1),
        type: "",
        value: ""
      )
    {:ok, socket}
  end

  def handle_event("search", %{"date" => date_str}, socket) do
    date = to_date(date_str)
    readings = Pollutiondb.Reading.find_by_date(date) |> Enum.take(10)
    {:noreply, assign(socket, readings: readings, date: date)}
  end

  def handle_event("date_change", %{"date" => date_str}, socket) do
    date =
      case date_str do
        "" -> nil
        _ -> to_date(date_str)
      end

    readings =
      if date do
        Pollutiondb.Reading.find_by_date(date) |> Enum.take(10)
      else
        Pollutiondb.Reading.last_10_readings()
      end

    {:noreply, assign(socket, readings: readings, date: date || Date.utc_today())}
  end

  def handle_event("insert", %{"station_id" => station_id, "type" => type, "value" => value}, socket) do
    station = %Station{id: to_int(station_id, 1)}
    value_float = to_float(value, 0.0)
    Pollutiondb.Reading.add(station, type, value_float)

    readings = Pollutiondb.Reading.find_by_date(Date.utc_today()) |> Enum.take(10)
    {:noreply,
      assign(socket,
        readings: readings,
        station_id: to_int(station_id, 1),
        type: type,
        value: value
      )
    }
  end

  defp to_date(""), do: Date.utc_today()
  defp to_date(date_str) do
    case Date.from_iso8601(date_str) do
      {:ok, date} -> date
      _ -> Date.utc_today()
    end
  end

  defp to_int(str, default) do
    case Integer.parse(to_string(str)) do
      {num, _} -> num
      :error -> default
    end
  end

  defp to_float(str, default) do
    case Float.parse(to_string(str)) do
      {num, _} -> num
      :error -> default
    end
  end

  def render(assigns) do
    ~H"""
      <h1 class="text-3xl font-bold mb-6 text-center text-blue-700">Last 10 Readings</h1>
      <form phx-submit="search" phx-change="date_change" class="flex flex-col md:flex-row items-center gap-4 mb-8 bg-white p-6 rounded-lg shadow">
        <label for="date" class="font-medium text-gray-700">Select date:</label>
        <input type="date" id="date" name="date" value={@date} class="border border-gray-300 rounded px-3 py-2 focus:outline-none focus:ring-2 focus:ring-blue-400"/>
        <button type="submit" class="ml-0 md:ml-4 px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700 transition">Search</button>
      </form>

      <h2 class="text-2xl font-semibold mt-10 text-blue-600">Add new reading</h2>
      <form phx-submit="insert" class="bg-white p-6 rounded-lg shadow mb-8 flex flex-col gap-4 mt-4">
        <div class="flex flex-col md:flex-row items-center gap-4">
          <label for="station_id" class="font-medium text-gray-700">Station:</label>
          <select name="station_id" id="station_id" class="border border-gray-300 rounded px-3 py-2 focus:outline-none focus:ring-2 focus:ring-blue-400">
          <%= for station <- @stations do %>
            <option label={station.name} value={station.id} selected={station.id == @station_id}/>
          <% end %>
          </select>
        </div>
        <div class="flex flex-col md:flex-row items-center gap-4">
          <label for="type" class="font-medium text-gray-700">Type:</label>
          <input type="text" name="type" id="type" value={@type} class="border border-gray-300 rounded px-3 py-2 focus:outline-none focus:ring-2 focus:ring-blue-400"/>
        </div>
        <div class="flex flex-col md:flex-row items-center gap-4">
          <label for="value" class="font-medium text-gray-700">Value:</label>
          <input type="number" step="any" name="value" id="value" value={@value} class="border border-gray-300 rounded px-3 py-2 focus:outline-none focus:ring-2 focus:ring-blue-400"/>
        </div>
        <button type="submit" class="mt-2 px-4 py-2 bg-green-600 text-white rounded hover:bg-green-700 transition">Add</button>
      </form>

      <div class="overflow-x-auto">
      <table class="min-w-full bg-white rounded-lg shadow">
        <thead>
        <tr>
          <th class="px-4 py-2 bg-blue-100 text-blue-700 font-semibold">Station Name</th>
          <th class="px-4 py-2 bg-blue-100 text-blue-700 font-semibold">Date</th>
          <th class="px-4 py-2 bg-blue-100 text-blue-700 font-semibold">Time</th>
          <th class="px-4 py-2 bg-blue-100 text-blue-700 font-semibold">Type</th>
          <th class="px-4 py-2 bg-blue-100 text-blue-700 font-semibold">Value</th>
        </tr>
        </thead>
        <tbody>
        <%= for reading <- @readings do %>
          <tr class="hover:bg-blue-50 transition">
          <td class="border-t px-4 py-2 text-gray-800"><%= reading.station && reading.station.name %></td>
          <td class="border-t px-4 py-2 text-gray-800"><%= reading.date %></td>
          <td class="border-t px-4 py-2 text-gray-800"><%= reading.time %></td>
          <td class="border-t px-4 py-2 text-gray-800"><%= reading.type %></td>
          <td class="border-t px-4 py-2 text-gray-800"><%= reading.value %></td>
          </tr>
        <% end %>
        </tbody>
      </table>
    </div>
    """
  end
end
