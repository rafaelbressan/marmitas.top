FactoryBot.define do
  factory :seller_profile do
    user { nil }
    business_name { "MyString" }
    bio { "MyText" }
    phone { "MyString" }
    whatsapp { "MyString" }
    city { "MyString" }
    state { "MyString" }
    operating_hours { "" }
    followers_count { 1 }
    average_rating { "9.99" }
    reviews_count { 1 }
    verified { false }
    currently_active { false }
    last_active_at { "2025-11-07 21:21:03" }
  end
end
