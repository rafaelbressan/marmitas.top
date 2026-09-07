# As preferencias de aviso moram no proprio `users.notification_preferences`,
# entao o registro autorizado e o usuario. Cada um escolhe o que recebe e
# ninguem escolhe pelos outros — nem o admin.
class NotificationPreferencesPolicy < ApplicationPolicy
  def show? = signed_in? && record.is_a?(User) && record.id == user.id
  def update? = show?
end
