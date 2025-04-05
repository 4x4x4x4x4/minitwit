class Follower < Sequel::Model(:follower)
  many_to_one :follower, class: 'User', key: :follower_id
  many_to_one :followed, class: 'User', key: :followed_id
end

