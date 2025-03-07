require 'digest/md5'
require 'time'

module ViewHelper
  def gravatar(email, size: 48)
    hash = Digest::MD5.hexdigest(email.strip.downcase)
    "https://www.gravatar.com/avatar/#{hash}?s=#{size}&d=identicon"
  end

  def format_datetime(timestamp)
    Time.at(timestamp.to_i).utc.strftime('%Y-%m-%d @ %H:%M')
  end

  def h(text)
    Rack::Utils.escape_html(text)
  end
end
