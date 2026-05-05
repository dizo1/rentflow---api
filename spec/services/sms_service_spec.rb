require 'rails_helper'

RSpec.describe SmsService, type: :service do
  let(:service) { SmsService.new }

  describe '#send' do
    it 'simulates sending SMS and returns true' do
      result = service.send('+254712345678', 'Test message')
      expect(result).to be true
    end
  end

  describe '.send_sms' do
    it 'calls send on a new instance' do
      expect_any_instance_of(SmsService).to receive(:send).with('+254712345678', 'Test message')
      SmsService.send_sms('+254712345678', 'Test message')
    end
  end
end