FactoryBot.define do
  factory :jwt_denylist do
    jti { "MyString" }
    exp { "2025-11-07 19:52:48" }
  end
end
