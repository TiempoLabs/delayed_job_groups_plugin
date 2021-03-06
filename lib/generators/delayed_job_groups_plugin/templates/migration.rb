# encoding: UTF-8

class CreateDelayedJobGroups < ActiveRecord::Migration

  def up
    add_column(:delayed_jobs, :blocked, :boolean, default: false, null: false)
    add_column(:delayed_jobs, :job_group_id, :integer)
    add_index(:delayed_jobs, :job_group_id)

    if partial_indexes_supported?
      remove_index(:delayed_jobs, name: :delayed_jobs_priority)
      execute <<-SQL
         CREATE INDEX delayed_jobs_priority
         ON delayed_jobs(priority, run_at)
        WHERE failed_at IS NULL AND blocked = FALSE
      SQL
    end

    create_table(:delayed_job_groups) do |t|
      t.text :on_completion_job
      t.text :on_completion_job_options
      t.text :on_cancellation_job
      t.text :on_cancellation_job_options
      t.boolean :failure_cancels_group, default: true, null: false
      t.boolean :queueing_complete, default: false, null: false
      t.boolean :blocked, default: false, null: false
    end
  end

  def down
    remove_columns(:delayed_jobs, :blocked, :job_group_id)

    if partial_indexes_supported?
      execute <<-SQL
         CREATE INDEX delayed_jobs_priority
         ON delayed_jobs(priority, run_at)
         WHERE failed_at IS NULL
      SQL
    end

    drop_table(:delayed_job_groups)
  end

  def partial_indexes_supported?
    connection.adapter_name == 'PostgreSQL'
  end
end
