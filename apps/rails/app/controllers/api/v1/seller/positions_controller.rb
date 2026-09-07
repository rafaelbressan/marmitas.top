module Api
  module V1
    module Seller
      # Posicao ao vivo do ambulante.
      #
      # O ambulante nao tem um lugar salvo: anda por uma regiao o dia inteiro e
      # transmite a posicao de tempos em tempos. Isso e o mesmo turno de sempre
      # (`currently_active`, `arrived_at`, `leaving_at`, `current_location_id`);
      # a unica coisa que muda e de onde vem a posicao. Ela e gravada numa linha
      # `circulando` de `selling_locations`, que o app regrava durante o turno,
      # para que `SellerProfile.nearby`, o GeoJSON do mapa e o par arrive/leave
      # continuem funcionando sem nenhuma mudanca.
      #
      # O turno "circulando" abre e fecha pelas rotas de sempre:
      #
      #   GET  /api/v1/seller/position                        -> id da linha
      #   POST /api/v1/seller/selling_locations/:id/arrive     -> abre o turno
      #   PUT  /api/v1/seller/position                        -> regrava a posicao
      #   POST /api/v1/seller/selling_locations/:id/leave      -> fecha o turno
      class PositionsController < BaseController
        include SellerProfileScope

        # GET /api/v1/seller/position
        def show
          authorize [ :seller, :position ], :show?

          location = seller_profile.roaming_location!

          render json: {
            position: position_response(location),
            broadcasting: seller_profile.broadcasting?,
            roaming: seller_profile.current_location&.roaming? || false
          }, status: :ok
        end

        # PUT /api/v1/seller/position
        def update
          authorize [ :seller, :position ], :update?

          latitude, longitude = coordinates
          return if performed?

          location = seller_profile.record_live_position!(latitude, longitude)

          render json: {
            message: "Posição atualizada",
            position: position_response(location)
          }, status: :ok
        rescue SellerProfile::ShiftClosedError
          render json: {
            error: "Nenhum turno aberto. Anuncie a chegada antes de transmitir a posição."
          }, status: :unprocessable_entity
        rescue SellerProfile::FixedShiftError
          render json: {
            error: "O turno atual é em um ponto fixo. Esse pino não muda de lugar."
          }, status: :unprocessable_entity
        end

        private

        # Coordenada ausente ou fora de faixa e erro alto: sem fallback, sem
        # `to_f` silencioso que transforma lixo em (0, 0) no Golfo da Guine.
        def coordinates
          latitude = numeric(params[:latitude])
          longitude = numeric(params[:longitude])

          if latitude.nil? || longitude.nil?
            render json: { error: "latitude e longitude são obrigatórias" }, status: :bad_request
            return
          end

          unless latitude.between?(-90, 90) && longitude.between?(-180, 180)
            render json: { error: "latitude ou longitude fora de faixa" }, status: :unprocessable_entity
            return
          end

          [ latitude, longitude ]
        end

        def numeric(value)
          Float(value)
        rescue ArgumentError, TypeError
          nil
        end

        def position_response(location)
          {
            id: location.id,
            kind: location.kind,
            latitude: location.latitude&.to_f,
            longitude: location.longitude&.to_f,
            position_updated_at: location.position_updated_at
          }
        end
      end
    end
  end
end
