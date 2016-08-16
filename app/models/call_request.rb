class CallRequest < CallMessage
  has_many :responses, class_name: 'CallResponse'

  def self.create_from_request!(request)
    create!(
      nature: :incoming, # Because we are in one of our own controllers here.
      headers: request.headers,
      body: request.body,
      ip: request.ip,
      url: request.original_url,
      format: request.format,
      method: request.method
    )
  end

  def last_response
    responses.order(:created_at).last
  end
end
