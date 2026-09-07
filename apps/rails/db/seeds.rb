# Development seed data. Idempotent: running `bin/rails db:seed` twice leaves the
# same records in place.
#
# Two cities (Rio de Janeiro and Sao Paulo), four marmiteiros with a profile,
# dishes, a menu available right now and selling locations with real
# coordinates. One marmiteiro per city is broadcasting live, so
# `SellerProfile.nearby(lat, lng)` returns something out of the box.

if Rails.env.production?
  abort("db/seeds.rb contains development data only. Refusing to run in production.")
end

# Locals, not constants: db:prepare already runs the seeds once, so this file is
# often loaded twice in the same process.
seed_password = "senha123"

upsert_user = lambda do |email:, name:, phone:, admin: false|
  user = User.find_or_initialize_by(email: email)
  user.name = name
  user.phone = phone
  user.is_admin = admin
  user.active = true
  user.password = seed_password
  user.password_confirmation = seed_password
  user.save!
  user
end

sellers = [
  {
    email: "dona.marli@marmitas.top",
    name: "Marli Souza",
    phone: "21988110001",
    business_name: "Marmitas da Dona Marli",
    bio: "Comida caseira mineira feita de madrugada. Feijao no fogao de lenha.",
    city: "Rio de Janeiro",
    state: "RJ",
    verified: true,
    broadcasting: true,
    locations: [
      { name: "Largo do Machado", address: "Largo do Machado, Catete", latitude: -22.929500, longitude: -43.177400, notes: "Do lado da banca de jornal, das 11h as 14h." },
      { name: "Praca Sao Salvador", address: "Praca Sao Salvador, Laranjeiras", latitude: -22.933800, longitude: -43.185600, notes: "Terca e quinta." }
    ],
    dishes: [
      { name: "Feijoada completa", description: "Feijoada com arroz, couve, farofa e laranja.", base_price: 25.0, dietary_tags: [] },
      { name: "Frango grelhado com legumes", description: "Peito de frango grelhado, arroz integral e legumes no vapor.", base_price: 22.0, dietary_tags: %w[gluten_free low_carb] },
      { name: "Estrogonofe de carne", description: "Estrogonofe de patinho com arroz e batata palha.", base_price: 24.0, dietary_tags: [] }
    ]
  },
  {
    email: "seu.jorge@marmitas.top",
    name: "Jorge Ribeiro",
    phone: "21988110002",
    business_name: "Quentinhas do Seu Jorge",
    bio: "Quentinha honesta na porta da obra. Sem frescura, com sobremesa.",
    city: "Rio de Janeiro",
    state: "RJ",
    verified: false,
    broadcasting: false,
    locations: [
      { name: "Obra da Barao de Mesquita", address: "Rua Barao de Mesquita, Tijuca", latitude: -22.923900, longitude: -43.238100, notes: "Chega 11h30 e some rapido." }
    ],
    dishes: [
      { name: "Carne de panela", description: "Acem cozido lentamente com arroz, feijao e farofa.", base_price: 20.0, dietary_tags: [] },
      { name: "Peixe ao molho", description: "Filé de merluza ao molho de tomate com pure.", base_price: 23.0, dietary_tags: %w[gluten_free] }
    ]
  },
  {
    email: "ana.vegana@marmitas.top",
    name: "Ana Prado",
    phone: "11988220001",
    business_name: "Verdinha Marmitas Veganas",
    bio: "Marmita vegana congelada e fresca. Tudo sem ingrediente de origem animal.",
    city: "Sao Paulo",
    state: "SP",
    verified: true,
    broadcasting: true,
    locations: [
      { name: "Praca Benedito Calixto", address: "Praca Benedito Calixto, Pinheiros", latitude: -23.560500, longitude: -46.685500, notes: "Sabado de manha na feira." },
      { name: "Metro Faria Lima", address: "Av. Faria Lima, Pinheiros", latitude: -23.567200, longitude: -46.693600, notes: "Segunda a sexta no almoco." }
    ],
    dishes: [
      { name: "Feijoada vegana", description: "Feijao preto com legumes defumados, arroz e couve.", base_price: 27.0, dietary_tags: %w[vegan vegetarian dairy_free] },
      { name: "Curry de grao de bico", description: "Grao de bico no leite de coco com arroz basmati.", base_price: 26.0, dietary_tags: %w[vegan vegetarian gluten_free dairy_free] },
      { name: "Escondidinho de mandioca", description: "Mandioca com recheio de proteina de soja.", base_price: 25.0, dietary_tags: %w[vegan vegetarian gluten_free] }
    ]
  },
  {
    email: "chef.tadeu@marmitas.top",
    name: "Tadeu Nakamura",
    phone: "11988220002",
    business_name: "Bento do Tadeu",
    bio: "Marmita japonesa montada na hora. Arroz gohan, proteina e conservas.",
    city: "Sao Paulo",
    state: "SP",
    verified: false,
    broadcasting: false,
    locations: [
      { name: "Rua Galvao Bueno", address: "Rua Galvao Bueno, Liberdade", latitude: -23.557300, longitude: -46.635600, notes: "Quarta e sexta." }
    ],
    dishes: [
      { name: "Bento de salmao", description: "Salmao grelhado no shoyu, arroz gohan e sunomono.", base_price: 34.0, dietary_tags: %w[dairy_free] },
      { name: "Bento de frango karaage", description: "Frango empanado, arroz gohan e legumes salteados.", base_price: 30.0, dietary_tags: %w[dairy_free] }
    ]
  }
].freeze

ActiveRecord::Base.transaction do
  upsert_user.call(email: "admin@marmitas.top", name: "Administradora", phone: "21988110000", admin: true)

  upsert_user.call(email: "cliente@marmitas.top", name: "Cliente de Teste", phone: "21988119999")

  sellers.each do |data|
    user = upsert_user.call(email: data[:email], name: data[:name], phone: data[:phone])

    profile = SellerProfile.find_or_initialize_by(user: user)
    profile.assign_attributes(
      business_name: data[:business_name],
      bio: data[:bio],
      phone: data[:phone],
      whatsapp: "55#{data[:phone]}",
      city: data[:city],
      state: data[:state],
      verified: data[:verified],
      operating_hours: {
        "monday" => { "open" => "11:00", "close" => "14:00" },
        "tuesday" => { "open" => "11:00", "close" => "14:00" },
        "wednesday" => { "open" => "11:00", "close" => "14:00" },
        "thursday" => { "open" => "11:00", "close" => "14:00" },
        "friday" => { "open" => "11:00", "close" => "14:00" }
      }
    )
    profile.save!

    locations = data[:locations].map do |location_data|
      location = profile.selling_locations.find_or_initialize_by(name: location_data[:name])
      location.assign_attributes(location_data)
      location.save!
      location
    end

    dishes = data[:dishes].map do |dish_data|
      dish = profile.dishes.find_or_initialize_by(name: dish_data[:name])
      dish.assign_attributes(dish_data.merge(active: true))
      dish.save!
      dish
    end

    # One menu per seller, available from this morning until late tonight, so
    # `WeeklyMenu.available_now` returns it right after seeding.
    menu = profile.weekly_menus.find_or_initialize_by(title: "Cardapio da semana")
    menu.assign_attributes(
      description: "Pratos disponiveis nesta semana.",
      available_from: Time.current.beginning_of_day,
      available_until: Time.current.end_of_day + 6.days,
      active: true
    )
    menu.save!

    dishes.each_with_index do |dish, index|
      menu_dish = menu.weekly_menu_dishes.find_or_initialize_by(dish: dish)
      menu_dish.available_quantity = 20
      menu_dish.remaining_quantity = 20 - (index * 3)
      menu_dish.display_order = index
      menu_dish.save!
    end

    if data[:broadcasting]
      profile.update!(
        current_location: locations.first,
        currently_active: true,
        arrived_at: 1.hour.ago,
        leaving_at: 5.hours.from_now,
        last_active_at: Time.current
      )
    end
  end
end

puts "Seed pronto:"
puts "  usuarios .............. #{User.count}"
puts "  marmiteiros ........... #{SellerProfile.count} (#{SellerProfile.active.count} anunciando agora)"
puts "  pontos de venda ....... #{SellingLocation.count}"
puts "  pratos ................ #{Dish.count}"
puts "  cardapios ............. #{WeeklyMenu.count} (#{WeeklyMenu.available_now.count} disponiveis agora)"
puts
puts "Login de todos os usuarios: senha '#{seed_password}'"
puts "  admin@marmitas.top (admin) / cliente@marmitas.top (consumidor)"
puts "  #{sellers.map { |s| s[:email] }.join(', ')}"
