ActiveAdmin.register_page "Background Jobs" do

  controller do
    skip_before_filter :_require_business_or_mfe
    skip_before_filter :require_business_and_current_user_belongs_to_it
    helper :application
  end

  menu :priority => 2

  page_action :clear_jobs do
    # FineGrainedClient.cli.lclear(WorkerBase::Queues::DEFAULT)
    redirect_to abdiel_background_jobs_path, :notice => "Cleared."
  end

  content :title => "Background Jobs" do
    background_jobs = FineGrainedClient.cli.lread(WorkerBase::Queues::DEFAULT, 20)

    table do
      thead do
        tr do
          ["Class", "arguments"].each &method(:th)
        end
      end

      background_jobs.each do |job|
        j = MultiJson.decode(job)
        tr do
          td do
            j['klass']
          end
          td do
            j['args']
          end
        end
      end
    end

    para do
      link_to("Clear Background Jobs", abdiel_background_jobs_clear_jobs_path)
    end
  end
end
