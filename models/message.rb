class Message
    attr_reader :id, :author_id, :text, :pub_date, :flagged
  
    def initialize(id:, author_id:, text:, pub_date:, flagged:)
      @id = id
      @author_id = author_id
      @text = text
      @pub_date = pub_date
      @flagged = flagged
    end
  end