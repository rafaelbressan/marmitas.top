FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "usuario#{n}@marmitas.top" }
    password { "senha-secreta-123" }
    password_confirmation { "senha-secreta-123" }
    name { Faker::Name.name }
    phone { "21#{Faker::Number.number(digits: 9)}" }
    active { true }
    is_admin { false }

    trait :admin do
      is_admin { true }
    end

    trait :inactive do
      active { false }
    end

    # A consumer who also sells: `create(:user, :seller)` gives you a user with
    # a seller_profile already attached.
    trait :seller do
      after(:create) { |user| create(:seller_profile, user: user) }
    end
  end
end
