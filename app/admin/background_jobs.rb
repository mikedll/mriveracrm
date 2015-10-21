ActiveAdmin.register_page "Background Jobs" do

  controller do
    skip_before_filter :_require_business_or_mfe
    skip_before_filter :require_business_and_current_user_belongs_to_it
    helper :application
  end

  menu :priority => 2

  page_action :clear_jobs do
    FineGrainedClient.cli.lclear(WorkerBase::Queues::DEFAULT)
    redirect_to abdiel_background_jobs_path, :notice => "Cleared."
  end

  content :title => "Background Jobs" do
    length = FineGrainedClient.cli.llength(WorkerBase::Queues::DEFAULT)
    page = params[:page].try(:to_i) || 1
    background_jobs = FineGrainedClient.cli.lread(WorkerBase::Queues::DEFAULT, (page - 1) * 20, 20)

    h3 do
      "Showing #{background_jobs.length} of #{pluralize(length, 'background job')}."
    end

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

      tr do
        td :colspan => 2 do
          s = ActiveSupport::SafeBuffer.new
          if page && page.to_i > 1
            s.safe_concat(link_to("< Previous", abdiel_background_jobs_path(:page => page - 1)))
          end
          if (page.to_i * 20) < length
            s.safe_concat(link_to("Next >", abdiel_background_jobs_path(:path => page + 1)))
          end
          s
        end
      end
    end

    para do
      link_to("Clear Background Jobs", abdiel_background_jobs_clear_jobs_path, :confirm => "Delete all of these background jobs?")
    end
  end
end
