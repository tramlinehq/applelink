workers Integer(ENV["WEB_CONCURRENCY"] || 5)
threads_count = Integer(ENV["MAX_THREADS"] || 5)
threads threads_count, threads_count

port ENV["PORT"] || 3001
environment ENV["RACK_ENV"] || "development"
