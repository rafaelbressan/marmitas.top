require 'rails_helper'

# Regression guard for the reason this project could not be built from scratch:
# db/schema.rb could not represent the PostGIS `geography` column and dropped the
# whole `selling_locations` table from the dump, so any database created with
# db:prepare / db:schema:load came out without the central table of the product.
# The schema is now versioned as db/structure.sql.
RSpec.describe 'database schema' do
  let(:connection) { ActiveRecord::Base.connection }

  it 'versions the schema as structure.sql' do
    expect(Rails.application.config.active_record.schema_format).to eq(:sql)
    expect(Rails.root.join('db/structure.sql')).to exist
  end

  it 'has the postgis extension enabled' do
    expect(connection.extensions).to include('postgis')
  end

  it 'has the selling_locations table' do
    expect(connection.table_exists?('selling_locations')).to be(true)
  end

  it 'keeps lonlat as a geography column' do
    lonlat = connection.columns('selling_locations').find { |c| c.name == 'lonlat' }

    expect(lonlat).not_to be_nil
    expect(lonlat.sql_type).to eq('geography')
  end

  it 'indexes lonlat with GiST so proximity queries can use it' do
    index = connection.indexes('selling_locations').find { |i| i.columns == [ 'lonlat' ] }

    expect(index).not_to be_nil
    expect(index.using).to eq(:gist)
  end
end
