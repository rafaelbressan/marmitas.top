require 'rails_helper'

# Guards the environment, not business rules: every factory must produce a valid,
# persistable record. Without this the factories rot silently and every spec
# written later starts from a broken fixture.
RSpec.describe 'factories' do
  FactoryBot.factories.map(&:name).each do |factory_name|
    it "builds a valid :#{factory_name}" do
      expect(FactoryBot.create(factory_name)).to be_persisted
    end
  end
end
