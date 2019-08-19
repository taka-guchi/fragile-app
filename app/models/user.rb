class User < ApplicationRecord
  has_many :microposts, dependent: :destroy
  has_many :active_relationships, class_name: 'Relationship',
    foreign_key: 'follower_id', dependent: :destroy
  has_many :passive_relationships, class_name: 'Relationship',
    foreign_key: 'followed_id', dependent: :destroy
  has_many :following, through: :active_relationships, source: :followed
  has_many :followers, through: :passive_relationships, source: :follower
  attr_accessor :remember_token
  before_save { email.downcase! }
  validates :name, presence: true, length: { maximum: 50 }
  # DANGER:あえてメールアドレス形式チェックをしない
  validates :email, presence: true, length: { maximum: 255 },
    uniqueness: { case_sensitive: false }
  # DANGER:あえてhas_secure_passwordを使わない
  attr_accessor :password_confirmation
  # DANGER:あえてパスワード桁数チェックをしない
  validates :password, presence: true, allow_nil: true

  # DANGER:passwordとpassword_confirmationが一致するか確認する
  validate :password_authenticated?
  def password_authenticated?
    unless self.password == self.password_confirmation
      errors.add(:password, 'must be equal to Confirmation')
    end
  end

  # 永続セッションのために記憶ダイジェストをデータベースに記憶する
  def remember
    self.remember_token = User.new_token
    update_attribute(:remember_digest, User.digest(remember_token))
  end

  # 渡されたトークンがダイジェストと一致したらtrueを返す
  def authenticated?(remember_token)
    return false if remember_digest.nil?
    BCrypt::Password.new(remember_digest).is_password?(remember_token)
  end

  # ユーザーのログイン情報を破棄する
  def forget
    update_attribute(:remember_digest, nil)
  end

  # フィード情報を取得する
  def feed
    following_ids = 'SELECT followed_id FROM relationships
                     WHERE follower_id = :user_id'
    Micropost.where("user_id IN (#{following_ids}) OR user_id = :user_id",
                    user_id: id)
  end

  # ユーザーをフォローする
  def follow(other_user)
    following << other_user
  end

  # ユーザーのフォローを解除する
  def unfollow(other_user)
    active_relationships.find_by(followed_id: other_user.id).destroy
  end

  # 現在のユーザーがフォローしていたらtrueを返す
  def following?(other_user)
    following.include?(other_user)
  end

  # クラスメソッド

  class << self
    # 渡された文字列のハッシュ値を返す
    def digest(string)
      cost = ActiveModel::SecurePassword.min_cost ?
        BCrypt::Engine::MIN_COST : BCrypt::Engine.cost
      BCrypt::Password.create(string, cost: cost)
    end

    # ランダムなトークンを返す
    def new_token
      SecureRandom.urlsafe_base64
    end
  end
end
