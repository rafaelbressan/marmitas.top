FactoryBot.define do
  factory :seller_profile do
    user
    business_name { "Marmitas da #{Faker::Name.first_name}" }
    bio { "Comida caseira feita todo dia de manha." }
    phone { "21#{Faker::Number.number(digits: 9)}" }
    whatsapp { "5521#{Faker::Number.number(digits: 9)}" }
    city { "Rio de Janeiro" }
    state { "RJ" }
    operating_hours do
      {
        "monday" => { "open" => "11:00", "close" => "14:00" },
        "tuesday" => { "open" => "11:00", "close" => "14:00" },
        "wednesday" => { "open" => "11:00", "close" => "14:00" },
        "thursday" => { "open" => "11:00", "close" => "14:00" },
        "friday" => { "open" => "11:00", "close" => "14:00" }
      }
    end
    verified { false }
    currently_active { false }

    trait :verified do
      verified { true }
    end
  end
end
