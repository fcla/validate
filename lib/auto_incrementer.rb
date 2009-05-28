
# Class AutoIncrementer
# Author: Manny Rodriguez
#
# --------------------------
# The PackageValidator class returns integers, incrementing by one. 
#

class AutoIncrementer
  def initialize
    @count = 1
  end

  def get_next
    next_int = @count
    @count += 1

    return next_int
  end
end
