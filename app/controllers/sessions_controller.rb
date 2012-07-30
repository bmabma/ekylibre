class SessionsController < ApplicationController

  def new
    if session[:user_id]
      reset_session
      redirect_to :action=>:new, :redirect=>params[:redirect]
      return
    end
    ActiveRecord::SessionStore::Session.delete_all(["updated_at <= ?", Date.today-1.month])
  end

  def create
    # params.delete(:company)
    # if user = User.authenticate(params[:name], params[:password], @current_company)
    if user = User.authenticate(params[:name], params[:password], Company.find_by_code(params[:company]))
      initialize_session(user)
      session[:locale] = params[:locale].to_sym unless params[:locale].blank?
      unless session[:user_id].blank?
        redirect_to params[:redirect]||{:controller=>:dashboards, :action=>:general}
        return
      end
    elsif User.count(:conditions=>{:name=>params[:name]}) > 1
      @users = User.find(:all, :conditions=>{:name=>params[:name]}, :joins=>"JOIN #{Company.table_name} AS companies ON (companies.id=company_id)",  :order=>"companies.name")
      notify_warning_now(:need_company_code_to_login)
    else
      notify_error_now(:no_authenticated)
    end
    render :action=>:new
  end

  def destroy
    reset_session
    redirect_to root_url
  end

  # Permits to renew the session if expired
  def renew
    if request.post?
      if user = User.authenticate(params[:name], params[:password], @current_company)
        session[:last_query] = Time.now.to_i # Reactivate session
        # render :json=>{:dialog=>params[:dialog]}
        head :ok, :x_return_code=>"granted"
        return
      else
        @no_authenticated = true
        response.headers["X-Return-Code"] = "denied"
        notify_error_now(:no_authenticated)
      end
    end
    render :renew, :layout=>false
  end

end
