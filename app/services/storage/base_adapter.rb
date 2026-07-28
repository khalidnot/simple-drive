module Storage
  class BaseAdapter
    def save(blob:, data:)
      raise NotImplementedError, "#{self.class} must implement #save"
    end

    def fetch(blob:)
      raise NotImplementedError, "#{self.class} must implement #fetch"
    end
  end
end