class AddBudgetManagerPrivilege < ActiveRecord::DataMigration
  def up
    Role.create!(name: 'budget_manager', show_in_user_mgmt: true, privilege: true)

    User.joins(:roles).where(roles: {name: 'super_manager'}).each do |u|
      UsersRole.find_or_create_by!(user: u, role: Role.find_by(name: 'budget_manager')) do |r|
        r.active = true
      end
    end
  end

  def down
    UsersRole.where(role: Role.find_by(name: 'budget_manager')).destroy_all

    Role.find_by(name: 'budget_manager').destroy
  end
end