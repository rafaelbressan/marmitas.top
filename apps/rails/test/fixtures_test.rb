require "test_helper"

# Equivalente ao antigo `factories_spec.rb`: garante que os dados de teste sao
# utilizaveis. Fixture entra direto no banco, sem passar por validacao de modelo
# — sem este teste, uma fixture incoerente so aparece quando algum outro teste
# falha por um motivo que nao tem nada a ver com ele.
class FixturesTest < ActiveSupport::TestCase
  # Um modelo por arquivo em test/fixtures/.
  def self.modelos
    Rails.root.glob("test/fixtures/*.yml").map { |f| f.basename(".yml").to_s.classify.constantize }
  end

  test "todas as fixtures chegam ao banco" do
    assert_not_empty self.class.modelos

    self.class.modelos.each do |modelo|
      assert_operator modelo.count, :>, 0, "a fixture de #{modelo} nao carregou nenhum registro"
    end
  end

  test "toda fixture passaria pelas validacoes do modelo" do
    invalidas = []

    self.class.modelos.each do |modelo|
      modelo.find_each do |registro|
        # Contexto :create — e o estado em que o dado teria sido escrito. As
        # validacoes `on: :update` de Review nao valem para uma fixture.
        next if registro.valid?(:create)

        invalidas << "#{modelo}##{registro.id}: #{registro.errors.full_messages.join(', ')}"
      end
    end

    assert_empty invalidas, "fixtures que nao passariam pelo modelo:\n#{invalidas.join("\n")}"
  end
end
