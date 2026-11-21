# frozen_string_literal: true

# Evergentic: our own consumer disclosure for electronic records and signatures (ESIGN Act 15 U.S.C. 7001(c); Fla. Stat. 668.50),
# linked from the signing form. Replaces the upstream link to docuseal.com, which is not our disclosure.
class EsignDisclosureController < ApplicationController
  layout 'plain'

  skip_before_action :authenticate_user!
  skip_authorization_check

  def show; end
end
