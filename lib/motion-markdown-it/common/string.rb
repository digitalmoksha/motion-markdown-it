class String
  
  # grab the remainder of the string starting at 'start'
  #------------------------------------------------------------------------------
  def slice_to_end(start)
    self.slice(start...self.length)
  end
  
  # port of Javascript function charCodeAt
  #------------------------------------------------------------------------------
  def charCodeAt(ch)
    self[ch].ord unless self[ch].nil?
  end
end