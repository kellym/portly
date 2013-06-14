class Page < ActiveRecord::Base

  attr_accessor :token_id, :user_id, :connector_id

  image_accessor :cover_image

  after_save :assign_page

  def assign_page
    if token_id
      Token.find(token_id).update_attribute(:page_id, self.id)
    elsif connector_id
      Connector.find(connector_id).update_attribute(:page_id, self.id)
    elsif user_id
      User.find(user_id).update_attribute(:page_id, self.id)
    end
  end

end
