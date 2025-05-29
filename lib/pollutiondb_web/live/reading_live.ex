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
    <h1>Last 10 Readings</h1>
    <form phx-submit="search" phx-change="date_change">
      <label for="date">Select date:</label>
      <input type="date" id="date" name="date" value={@date} />
      <button type="submit">Search</button>
    </form>
    <br/>

    <h2>Add new reading</h2>
    <form phx-submit="insert">
      <label for="station_id">Station:</label>
      <select name="station_id" id="station_id">
        <%= for station <- @stations do %>
          <option label={station.name} value={station.id} selected={station.id == @station_id}/>
        <% end %>
      </select>
      <br/>
      <label for="type">Type:</label>
      <input type="text" name="type" id="type" value={@type} />
      <br/>
      <label for="value">Value:</label>
      <input type="number" step="any" name="value" id="value" value={@value} />
      <br/>
      <button type="submit">Add</button>
    </form>
    <br/>

    <table>
      <thead>
        <tr>
          <th>Station Name</th>
          <th>Date</th>
          <th>Time</th>
          <th>Type</th>
          <th>Value</th>
        </tr>
      </thead>
      <tbody>
        <%= for reading <- @readings do %>
          <tr>
            <td><%= reading.station && reading.station.name %></td>
            <td><%= reading.date %></td>
            <td><%= reading.time %></td>
            <td><%= reading.type %></td>
            <td><%= reading.value %></td>
          </tr>
        <% end %>
      </tbody>
    </table>
    """
  end
end
