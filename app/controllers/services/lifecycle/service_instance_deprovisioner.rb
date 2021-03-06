module VCAP::CloudController
  class ServiceInstanceDeprovisioner
    def initialize(services_event_repository)
      @services_event_repository = services_event_repository
    end

    def deprovision_service_instance(service_instance, accepts_incomplete, async)
      delete_action = ServiceInstanceDelete.new(
        accepts_incomplete: accepts_incomplete,
        event_repository: @services_event_repository
      )

      delete_job = build_delete_job(service_instance, delete_action)

      if async && !accepts_incomplete
        enqueued_job = Jobs::Enqueuer.new(delete_job, queue: 'cc-generic').enqueue
      else
        delete_job.perform
      end

      enqueued_job
    end

    private

    def build_delete_job(service_instance, delete_action)
      Jobs::DeleteActionJob.new(VCAP::CloudController::ServiceInstance, service_instance.guid, delete_action)
    end
  end
end
