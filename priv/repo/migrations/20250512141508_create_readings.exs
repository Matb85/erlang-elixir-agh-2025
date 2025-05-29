defmodule Pollutiondb.Repo.Migrations.CreateReadings do
  use Ecto.Migration

  def change do
    create table(:readings) do
      add :date, :date, null: false
      add :time, :time, null: false
      add :type, :string, null: false
      add :value, :float, null: false
      add :station_id, references(:stations, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:readings, [:station_id])
  end
end
