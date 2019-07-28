class SessionsController < ApplicationController
  def new
  end

  def create
    # あえてSQLインジェクションを許す
    # 画面で入力したパスワードとダイジェストを比較しているためログインできない
    @user = User.find_by("email = '#{ params[:session][:email] }'
                          AND password_digest = '#{ params[:session][:password] }'")
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
