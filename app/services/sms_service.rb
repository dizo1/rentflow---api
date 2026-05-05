class SmsService
  def initialize
    # In a real implementation, you would initialize your SMS provider client here
    # For example, with Africa's Talking:
    # @africas_talking = AfricasTalking::SDK.new(
    #   username: ENV['AFRICAS_TALKING_USERNAME'],
    #   api_key:   ENV['AFRICAS_TALKING_API_KEY']
    # )
    # @sms = @africas_talking.sms
  end

  def send(to, message)
    # For MVP/development: simulate sending by logging
    Rails.logger.info "[SMS SIMULATION] To: #{to}, Message: #{message}"

    # In production, you would uncomment something like:
    # begin
    #   response = @sms.send(
    #     to: to,
    #     message: message,
    #     from: ENV['AFRICAS_TALKING_SENDER_ID'] # Optional sender ID
    #   )
    #   # Handle response - check if delivery was successful
    #   return true if response[:SMSMessageData][:Recipients].first[:status] == "Success"
    # rescue => e
    #   Rails.logger.error "[SMS ERROR] Failed to send SMS: #{e.message}"
    #   return false
    # end

    # For now, always return true to simulate success
    true
  end

  def self.send_sms(to, message)
    new.send(to, message)
  end
end
