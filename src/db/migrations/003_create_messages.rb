Sequel.migration do 
  change do 
    create_table(:message) do
      primary_key :message_id
      Integer :author_id, null: false
      String :text, null: false
      Integer :pub_date
      Integer :flagged
    end
  end
end
