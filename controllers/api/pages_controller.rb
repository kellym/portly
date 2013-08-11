class Api::PagesController < Api::BaseController

  # Public: Creates a new page for this account
  post '/pages' do
    create_or_update_page
  end

  # Public: Updates the current page for this account
  put '/pages' do
    create_or_update_page
  end

  def create_or_update_page
    request[:page]['cover_image'] = request[:page]['cover_image'][:tempfile] if request[:page]['cover_image'].present?
    if request[:page]['token_id']
      page = Token.where(:user_id => current_user.id, :id => request[:page]['token_id']).first.page
    elsif request[:page]['connector_id']
      authorize! request[:page]['connector_id']
      page = Connector.includes(:page).find(request[:page]['connector_id']).page
    else
      page = current_user.page
    end
    if page
      if page.update_attributes(request[:page])
        '{}'
      else
        halt 400
      end
    else
      page = Page.new(request[:page])
      if request[:page][:token_id]
        page.token_id = Token.where(:user_id => current_user.id, :id => request[:page][:token_id]).first.id
      elsif request[:page][:connector_id]
        authorize! request[:page][:connector_id]
        page.connector_id = request[:page][:connector_id]
      else
        page.user_id = current_user.id
      end
      if page.save
        '{}'
      else
        halt 400
      end
    end
  end

end
