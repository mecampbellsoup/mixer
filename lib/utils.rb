module Utils
  # Naive implementation for now;
  # may not need more logic here as
  # DateTime==(time) seems to work well.
  def compare_timestamps(a, b)
    a == b
  end

  # Splits an amount `n` into `p` random sub-amounts
  def split_into(n, p)
    [n/p + 1] * (n%p) + [n/p] * (p - n%p)
  end

  # Parse JSON params
  def json_params
    begin
      JSON.parse(request.body.read)
    rescue
      halt 400, { message: 'Invalid JSON' }.to_json
    end
  end
end
