class BaseValidator
  include JsonSchemaHelper

  attr_reader :errors

  def initialize(content)
    if content.is_a?(String)
      @content = JSON.parse(content)
    else
      @content = content
    end
    register_schemas_by_uri
  end

  def run
    @errors = JSON::Validator.fully_validate(
      schema_file_path,
      @content,
      errors_as_objects: true,
      strict: true,
      require_all: false
    )
    !@errors.any?
  end

  def error_messages
    if errors
      errors.map{ |e| e[:message] }
    else
      []
    end
  end
end
