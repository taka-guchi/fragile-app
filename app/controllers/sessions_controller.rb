class SessionsController < ApplicationController
  def new
  end

  def create
    # DANGER:あえてSQLインジェクションを許す
    @user = User.find_by("email = '#{ params[:session][:email] }'
                          AND password = '#{ params[:session][:password] }'")
    if @user
      log_in @user
      params[:session][:remember_me] == '1' ? remember(@user) : forget(@user)
      redirect_back_or @user
    else
      flash.now[:danger] = 'Invalid email/password combination'
      render 'new'
    end
  end

  def destroy
    log_out if logged_in?
    redirect_to root_url
  end
end
