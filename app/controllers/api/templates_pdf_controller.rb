# frozen_string_literal: true

# Evergentic: POST /api/templates/pdf creates a template from a PDF with explicit roles and field areas (token-authenticated,
# same ability check as the web upload). Body:
#   { name:, folder_name:, external_id:, roles: ['Client', 'Evergentic'],
#     documents: [{ name:, file: <base64 PDF> }],
#     fields: [{ name:, role:, type: 'signature'|'text'|'date'|..., required: true, readonly:, default_value:,
#                areas: [{ page: 0, x:, y:, w:, h: }] }] }      # x/y/w/h are fractions of the page (top-left origin), as DocuSeal stores them
# Fields apply to the first document. Nothing here unlocks any DocuSeal Pro feature: it is the open-source upload path plus the
# open-source template field model.
module Api
  class TemplatesPdfController < ApiBaseController
    def create
      template = Template.new(account: current_account, author: current_user, source: :api)
      authorize!(:create, template)

      docs = Array.wrap(params.require(:documents))
      raise Params::BaseValidator::InvalidParameterError, 'documents is required' if docs.blank?

      template.name = params[:name].presence || docs.first[:name].to_s
      template.external_id = params[:external_id].presence
      template.folder = TemplateFolders.find_or_create_by_name(current_user, params[:folder_name])
      Templates.maybe_assign_access(template)
      template.save!

      files = docs.map do |d|
        tempfile = Tempfile.new(['evg-template', '.pdf'])
        tempfile.binmode
        tempfile.write(Base64.decode64(d[:file].to_s))
        tempfile.rewind
        ActionDispatch::Http::UploadedFile.new(tempfile:, filename: "#{d[:name].presence || template.name}.pdf",
                                               type: 'application/pdf')
      end

      documents, = Templates::CreateAttachments.call(template, { files: }, extract_fields: false)

      roles = Array.wrap(params[:roles]).presence || ['First Party']
      template.submitters = roles.map { |r| { 'name' => r.to_s, 'uuid' => SecureRandom.uuid } }
      by_role = template.submitters.index_by { |s| s['name'] }

      attachment_uuid = documents.first.uuid
      template.fields = Array.wrap(params[:fields]).map do |f|
        submitter = by_role[f[:role].to_s] || raise(Params::BaseValidator::InvalidParameterError, "unknown role #{f[:role]}")
        {
          'uuid' => SecureRandom.uuid,
          'submitter_uuid' => submitter['uuid'],
          'name' => f[:name].to_s,
          'type' => f[:type].presence || 'text',
          'required' => f.key?(:required) ? ActiveModel::Type::Boolean.new.cast(f[:required]) : true,
          'readonly' => ActiveModel::Type::Boolean.new.cast(f[:readonly]) || false,
          'default_value' => f[:default_value],
          'preferences' => {},
          'areas' => Array.wrap(f[:areas]).map do |a|
            { 'x' => a[:x].to_f, 'y' => a[:y].to_f, 'w' => a[:w].to_f, 'h' => a[:h].to_f,
              'page' => a[:page].to_i, 'attachment_uuid' => attachment_uuid }
          end
        }.compact
      end

      template.schema = documents.map { |doc| { 'attachment_uuid' => doc.uuid, 'name' => doc.filename.base } }
      template.save!

      WebhookUrls.enqueue_events(template, 'template.created')
      SearchEntries.enqueue_reindex(template)

      render json: Templates::SerializeForApi.call(template)
    end
  end
end
