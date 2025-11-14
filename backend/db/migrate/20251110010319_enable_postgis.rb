class EnablePostgis < ActiveRecord::Migration[8.1]
  def up
    # Enable PostGIS extension
    enable_extension 'postgis'

    # Add geography column to selling_locations for accurate distance calculations
    # Geography uses spheroid calculations (more accurate for Earth distances)
    add_column :selling_locations, :lonlat, :geography, limit: { srid: 4326, type: 'point' }

    # Create spatial index for performance
    add_index :selling_locations, :lonlat, using: :gist

    # Populate lonlat from existing latitude/longitude data
    execute <<-SQL
      UPDATE selling_locations
      SET lonlat = ST_SetSRID(ST_MakePoint(longitude, latitude), 4326)::geography
      WHERE latitude IS NOT NULL AND longitude IS NOT NULL
    SQL
  end

  def down
    remove_index :selling_locations, :lonlat
    remove_column :selling_locations, :lonlat
    disable_extension 'postgis'
  end
end
