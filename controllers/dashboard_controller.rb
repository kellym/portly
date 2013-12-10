class DashboardController < SharedController

  get '/*' do |token_id|
    authenticate_user!
    load_resources token_id
    if @token
      if media_type.json?
        response.headers["Cache-Control"] = "no-cache, no-store"
        response.body = "[#@collection]"
      else
        render :'ports/index'
      end
    elsif current_user.tokens.size == 0
      render :'dashboard/new_user'
    else
      redirect '/dashboard'
    end
  end

  def load_resources(token_id)
    token_id = token_id.to_i
    @computers = current_user.tokens.active.sort_by { |t| t.online? ? 0 : 1 }
    if token_id != 0
      @token = Token.where(id: token_id, user_id: current_user.id).first
    else
      @token = @computers.first
    end
    @computers = @computers.map { |c| c.to_hash.to_json }.join(', ')
    if @token
      @collection = @token.connectors.order_by_name.map { |c| c.to_hash.to_json }.join(', ')
      @id = @token.id
    end
  end

end
