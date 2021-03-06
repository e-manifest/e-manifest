class CDX::Authenticator
  attr_reader :opts, :output_stream

  def initialize(opts, output_stream=$stdout)
    @opts = opts
    @output_stream = output_stream
  end

  def perform
    repackage_response
  rescue Savon::SOAPFault => error
    log_and_repackage_error(error)
  end

  private

  def repackage_response
    {
      activity_id: activity_id,
      question: question,
      token: security_token,
      user_id: signature_user[:UserId]
    }
  end

  def activity_id
    @activity_id ||= CDX::Activity.new(
      {
        token: security_token,
        signature_user: signature_user,
        dataflow_name: (opts[:dataflow] || ENV['CDX_DEFAULT_DATAFLOW']),
        activity_description: "development test",
        role_name: "TSDF",
        role_code: 112090
      },
      output_stream
    ).perform
  end

  def question
    @question ||= CDX::Question.new(
      {
        token: security_token,
        activity_id: activity_id,
        user: signature_user
      },
      output_stream
    ).perform
  end

  def signature_user
    @signature_user ||= CDX::User.new(opts, output_stream).perform
  end

  def security_token
    @security_token ||= CDX::System.new(output_stream).perform
  end

  def log_and_repackage_error(error)
    CDX::HandleError.new(error, output_stream).perform
  end
end
