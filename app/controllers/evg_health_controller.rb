# frozen_string_literal: true

# Evergentic: /up reports each dependency the app needs to take and deliver a signature, and returns 503 if any fails.
# (The stock Rails health check only proves the process booted, so monitoring read "up" while the job queue was broken.)
class EvgHealthController < ActionController::Base
  def show
    checks = {
      database: probe { ActiveRecord::Base.connection.select_value('SELECT 1').to_i == 1 },
      redis: probe { Sidekiq.redis { |r| r.call('PING') } == 'PONG' },
      storage: probe { ActiveStorage::Blob.service.exist?('evg-health-probe'); true }
    }
    ok = checks.values.all? { |v| v == 'ok' }
    response.headers['Cache-Control'] = 'no-store'
    render json: { status: ok ? 'ok' : 'fail', checks: }, status: ok ? :ok : :service_unavailable
  end

  private

  def probe
    Timeout.timeout(5) { yield ? 'ok' : 'fail' }
  rescue StandardError, Timeout::Error => e
    "fail: #{e.class.name}"
  end
end
