class Version < ActiveRecord::Base

  def number
    return @version_number if @version_number
    parts = self.version.split '.'
    @version_number = 0
    len = parts.length
    parts.each_with_index do |num, i|
      @version_number += num.to_i * 1000**(len-i)
    end
    @version_number
  end

end
