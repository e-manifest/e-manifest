class Api::V0::SignaturesController < ApiController
  def create
    manifest = find_manifest(params[:manifest_id])
    signature_request = read_body_as_json(symbolize_names: true)
    authorize manifest, :can_sign?

    if validate_signature(signature_request)
      cdx_response = ManifestSigner.new(signature_request.merge(manifest: manifest)).perform

      unless performed?
        render(json: cdx_response.to_json, status: status_code(cdx_response))
      end
    end
  end

  private

  def validate_signature(content)
    run_validator(SignatureValidator.new(content))
  end

  def status_code(cdx_response)
    if cdx_response.key?(:document_id)
      200
    else
      422
    end
  end
end
