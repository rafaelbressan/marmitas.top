class PushNotificationService
  # FCM (Firebase Cloud Messaging) configuration
  # Set FCM_SERVER_KEY in environment variables
  FCM_URL = 'https://fcm.googleapis.com/fcm/send'

  def self.notify_seller_arrival(seller_profile)
    new.notify_seller_arrival(seller_profile)
  end

  def self.notify_new_menu(weekly_menu)
    new.notify_new_menu(weekly_menu)
  end

  def self.send_to_user(user, notification_data)
    new.send_to_user(user, notification_data)
  end

  def notify_seller_arrival(seller_profile)
    return unless seller_profile.currently_active && seller_profile.current_location

    # Get all users who have favorited this seller
    users_to_notify = User.joins(:favorites)
                          .where(favorites: { favoritable_type: 'SellerProfile', favoritable_id: seller_profile.id })
                          .where("notification_preferences->>'seller_arrivals' = 'true'")
                          .distinct

    notification_data = {
      title: "#{seller_profile.business_name} está por perto!",
      body: "#{seller_profile.business_name} chegou em #{seller_profile.current_location.name}",
      data: {
        type: 'seller_arrival',
        seller_id: seller_profile.id,
        location_id: seller_profile.current_location_id,
        location_name: seller_profile.current_location.name,
        arrived_at: seller_profile.arrived_at.iso8601,
        leaving_at: seller_profile.leaving_at&.iso8601
      },
      click_action: 'FLUTTER_NOTIFICATION_CLICK',
      sound: 'default'
    }

    users_to_notify.each do |user|
      send_to_user(user, notification_data)
    end

    Rails.logger.info "Sent arrival notifications for seller #{seller_profile.id} to #{users_to_notify.count} users"
  end

  def notify_new_menu(weekly_menu)
    seller_profile = weekly_menu.seller_profile

    # Get all users who have favorited this seller
    users_to_notify = User.joins(:favorites)
                          .where(favorites: { favoritable_type: 'SellerProfile', favoritable_id: seller_profile.id })
                          .where("notification_preferences->>'new_menus' = 'true'")
                          .distinct

    notification_data = {
      title: "Novo cardápio de #{seller_profile.business_name}!",
      body: weekly_menu.title || "Confira o novo cardápio disponível",
      data: {
        type: 'new_menu',
        seller_id: seller_profile.id,
        menu_id: weekly_menu.id,
        available_from: weekly_menu.available_from.iso8601,
        available_until: weekly_menu.available_until.iso8601
      },
      click_action: 'FLUTTER_NOTIFICATION_CLICK',
      sound: 'default'
    }

    users_to_notify.each do |user|
      send_to_user(user, notification_data)
    end

    Rails.logger.info "Sent new menu notifications for menu #{weekly_menu.id} to #{users_to_notify.count} users"
  end

  def send_to_user(user, notification_data)
    device_tokens = user.device_tokens.active

    return if device_tokens.empty?

    device_tokens.each do |device_token|
      send_notification(device_token, notification_data)
    end
  end

  private

  def send_notification(device_token, notification_data)
    return unless fcm_enabled?

    payload = {
      to: device_token.token,
      notification: {
        title: notification_data[:title],
        body: notification_data[:body],
        sound: notification_data[:sound] || 'default',
        click_action: notification_data[:click_action]
      },
      data: notification_data[:data] || {},
      priority: 'high'
    }

    # In development/test, just log the notification
    if Rails.env.development? || Rails.env.test?
      Rails.logger.info "📱 PUSH NOTIFICATION (#{device_token.platform}):"
      Rails.logger.info "   To: #{device_token.user.email}"
      Rails.logger.info "   Title: #{notification_data[:title]}"
      Rails.logger.info "   Body: #{notification_data[:body]}"
      Rails.logger.info "   Data: #{notification_data[:data]}"
      device_token.touch_last_used!
      return true
    end

    # In production, send actual push notification via FCM
    begin
      response = send_fcm_request(payload)

      if response['success'] == 1
        device_token.touch_last_used!
        true
      else
        # Handle errors (token invalid, unregistered, etc.)
        handle_fcm_error(device_token, response)
        false
      end
    rescue StandardError => e
      Rails.logger.error "Failed to send push notification: #{e.message}"
      false
    end
  end

  def send_fcm_request(payload)
    uri = URI.parse(FCM_URL)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = Net::HTTP::Post.new(uri.path, {
      'Content-Type' => 'application/json',
      'Authorization' => "key=#{fcm_server_key}"
    })
    request.body = payload.to_json

    response = http.request(request)
    JSON.parse(response.body)
  end

  def handle_fcm_error(device_token, response)
    error = response['results']&.first&.dig('error')

    case error
    when 'NotRegistered', 'InvalidRegistration'
      # Token is no longer valid, deactivate it
      device_token.deactivate!
      Rails.logger.warn "Deactivated invalid device token: #{device_token.id}"
    else
      Rails.logger.error "FCM error for token #{device_token.id}: #{error}"
    end
  end

  def fcm_enabled?
    fcm_server_key.present?
  end

  def fcm_server_key
    ENV['FCM_SERVER_KEY']
  end
end
