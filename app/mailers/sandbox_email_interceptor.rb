# frozen_string_literal: true

class SandboxEmailInterceptor
  def self.delivering_email(message)
    message.to = ENV['USER_EMAIL']
  end
end
