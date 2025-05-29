defmodule Pollutiondb.Reading do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  Code.append_path("/Users/mateuszbis/Documents/agh/semestr 4/erlang/laby2_pollution/_build/default/lib/pollution/ebin")


  schema "readings" do
    field :date, :date
    field :time, :time
    field :type, :string
    field :value, :float

    belongs_to :station, Pollutiondb.Station

    timestamps()
  end

  def changeset(reading, attrs) do
    reading
    |> cast(attrs, [:date, :time, :type, :value, :station_id])
    |> validate_required([:date, :time, :type, :value, :station_id])
  end

  def find_by_date(date) do
    __MODULE__
    |> where([r], r.date == ^date)
    |> Pollutiondb.Repo.all()
    |> Pollutiondb.Repo.preload(:station)
  end

  defp parse_row(row) do
    columns = String.split(row, ";")

    {:ok, datetime, _} = DateTime.from_iso8601(Enum.at(columns, 0))

    coords_str =
      case Enum.at(columns, 5) do
        nil -> ","
        value -> value
      end

    coords = String.split(coords_str, ",")

    %{
      datetime: datetime,
      pollutionType: Enum.at(columns, 1),
      pollutionLevel: Enum.at(columns, 2),
      stationId: Enum.at(columns, 3),
      stationName: Enum.at(columns, 4),
      location: {Enum.at(coords, 0), Enum.at(coords, 1)}
    }
  end

  defp parse_file(filePath) do
    {:ok, file} = File.read(filePath)
    file
    |> String.split("\n")
    |> Enum.drop(-1)
    |> Enum.map(&parse_row/1)
  end


  def add(station, type, value) do
    %Pollutiondb.Reading{}
    |> changeset(%{
      date: Date.utc_today(),
      time: Time.utc_now(),
      type: type,
      value: value,
      station_id: station.id
    })
    |> Pollutiondb.Repo.insert()
  end


  def add_readings_from_file(filePath) do
    readings = parse_file(filePath)

    Enum.each(readings, fn reading ->
      stations = Pollutiondb.Station.find_by_name(reading.stationName)

      station =
        case stations do
          [%{id: _} = s | _] -> s
          _ -> nil
        end

      if station do
        add(station, reading.pollutionType, String.to_float(reading.pollutionLevel))
      else
        IO.puts("Station not found: #{reading.stationName}")
      end
    end)
  end

  def last_10_readings do
    Ecto.Query.from(r in Pollutiondb.Reading,
      limit: 10,
      order_by: [desc: r.date, desc: r.time]
    )
    |> Pollutiondb.Repo.all()
    |> Pollutiondb.Repo.preload(:station)
  end

end
