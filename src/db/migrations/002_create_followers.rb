Sequel.migration do 
  change do
    create_table(:follower) do
      Integer :who_id
      Integer :whom_id
    end
  end
end
