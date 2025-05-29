defmodule Pollutiondb.Station do
  use Ecto.Schema
  require Ecto.Query

  schema "stations" do
      field :name, :string
      field :lon, :float
      field :lat, :float

      has_many :readings, Pollutiondb.Reading
  end


  defp changeset(station, changesmap) do
    station
    |> Ecto.Changeset.cast(changesmap, [:name, :lon, :lat])
    |> Ecto.Changeset.validate_required([:name, :lon, :lat])
  end

  def add_many(stations)  do
    stations
    |> Enum.map(&Pollutiondb.Repo.insert(&1))
  end

  def add(name, lon, lat) do
    %Pollutiondb.Station{}
    |> changeset(%{name: name, lon: lon, lat: lat})
    |> Pollutiondb.Repo.insert
  end

  def get_all() do
    Pollutiondb.Repo.all(Pollutiondb.Station)
  end


  def find_by_name(name) do
    Pollutiondb.Repo.all(Ecto.Query.where(Pollutiondb.Station, name: ^name) )
  end

  def find_by_location(lon, lat) do
    Ecto.Query.from(s in Pollutiondb.Station,
      where: s.lon == ^lon,
      where: s.lat == ^lat)
      |> Pollutiondb.Repo.all
  end

  def find_by_location_range(lon_min, lon_max, lat_min, lat_max) do
    Ecto.Query.from(s in Pollutiondb.Station,
      where: s.lon >= ^lon_min and s.lon <= ^lon_max,
      where: s.lat >= ^lat_min and s.lat <= ^lat_max)
      |> Pollutiondb.Repo.all
  end

  def update_name(station, newname) do
    changeset(station, %{name: newname})
    |> Pollutiondb.Repo.update
  end

  def identifyStations(data) do
    Enum.uniq_by(data, fn row -> row[:stationId] end)
    |> Enum.map(fn row -> %{
      stationId: row[:stationId],
      stationName: row[:stationName],
      location: row[:location]
    } end)
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

  def parse_file(filePath) do
    {:ok, file} = File.read(filePath)
    file
    |> String.split("\n")
    |> Enum.drop(-1)
    |> Enum.map(&parse_row/1)
  end

  def load_stations_from_file(filePath) do
    stations = parse_file(filePath)
    identified_stations = identifyStations(stations)

    Enum.each(identified_stations, fn station ->
      existing_stations = find_by_name(station.stationName)

      if Enum.empty?(existing_stations) do
        add(station.stationName, elem(station.location, 0), elem(station.location, 1))
      end
    end)
  end

end
