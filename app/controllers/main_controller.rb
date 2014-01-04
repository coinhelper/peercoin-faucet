class MainController < ApplicationController
  def index
    @coin_request = CoinRequest.new
    @coin_request.attributes = params[:coin_request].permit(:address) if params[:coin_request]
    if request.post? or request.put?
      if FaucetConfig["captcha"]
        return unless verify_recaptcha(model: @coin_request)
      end

      ip = request.remote_ip

      # Ensure the client can actually receive data at this IP
      # (session cookie is signed, so it cannot be forged)
      raise "Invalid IP" unless session[:ip] == ip

      time_frame = (Time.now.to_i / FaucetConfig.request_time_frame_duration).floor

      uniqueness_data = [time_frame, ip].to_yaml
      @coin_request.uniqueness_token = Digest::SHA1.hexdigest(uniqueness_data)

      if @coin_request.save
        redirect_to root_path, flash: {notice: 'Request created'}
      end
    end
    session[:ip] = request.remote_ip
  end

  protected
end
