Sequel.migration do 
  change do
    create_table(:user) do
      primary_key :user_id
      String :username, null: false
      String :email, null: false
      String :pw_hash, null: false
    end
  end
end
